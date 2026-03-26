---
-- @Liquipedia
-- page=Module:VRSStandingsData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local BooleanOperator = Condition.BooleanOperator
local Comparator = Condition.Comparator

local DATAPOINT_TYPE_MAIN = 'vrs_ranking'
local DATAPOINT_TYPE_LIVE = 'vrs_ranking_live'
local DATAPOINT_TYPE_LIQUIPEDIA = 'vrs_ranking_liquipedia'
local DATAPOINT_TYPE_PREDICTION = 'vrs_ranking_prediction'

---@class VRSStandingsData
local VRSStandingsData = {}

VRSStandingsData.DATAPOINT_TYPE_MAIN = DATAPOINT_TYPE_MAIN
VRSStandingsData.DATAPOINT_TYPE_LIVE = DATAPOINT_TYPE_LIVE
VRSStandingsData.DATAPOINT_TYPE_LIQUIPEDIA = DATAPOINT_TYPE_LIQUIPEDIA
VRSStandingsData.DATAPOINT_TYPE_PREDICTION = DATAPOINT_TYPE_PREDICTION

---@class VRSStandingsStanding
---@field place number
---@field points number
---@field local_place number?
---@field global_place number?
---@field opponent standardOpponent

---@class VRSStandingsSettings
---@field title string
---@field shouldFetch boolean
---@field fetchLimit number?
---@field filterRegion string?
---@field filterSubregion string?
---@field filterCountry string[]?
---@field filterCountryDisplay string?
---@field filterType 'none' | 'region' | 'subregion' | 'country'
---@field mainpage boolean
---@field datapointType string
---@field updated string

---Parses props, fetches or reads inline data, stores if needed, applies
---filters, and returns the final standings list alongside resolved settings.
---@param props table
---@return VRSStandingsStanding[]
---@return VRSStandingsSettings
function VRSStandingsData.getStandings(props)
	local datapointType = props.datapointType or DATAPOINT_TYPE_LIVE

	local updated
	if props.updated == 'latest' then
		assert(Logic.readBool(props.shouldFetch), '\'Latest\' can only be used for fetching data')
		updated = 'latest'
	elseif props.updated then
		updated = DateExt.toYmdInUtc(props.updated)
	else
		if Logic.readBool(props.shouldFetch) then
			updated = 'latest'
		else
			error('A date must be provided when not fetching data')
		end
	end

	---@type VRSStandingsSettings
	local settings = {
		title = props.title,
		shouldFetch = Logic.readBool(props.shouldFetch),
		fetchLimit = tonumber(props.fetchLimit),
		filterRegion = props.filterRegion,
		filterSubregion = props.filterSubregion,
		filterCountry = Array.parseCommaSeparatedString(props.filterCountry),
		filterCountryDisplay = props.filterCountryDisplay,
		mainpage = Logic.readBool(props.mainpage),
		datapointType = datapointType,
		updated = updated,
		filterType = 'none',
	}

	if settings.filterRegion then
		settings.filterType = 'region'
	elseif settings.filterSubregion then
		settings.filterType = 'subregion'
	elseif settings.filterCountry and #settings.filterCountry > 0 then
		settings.filterType = 'country'
	end

	---@type VRSStandingsStanding[]
	local standings = {}

	if settings.shouldFetch then
		local fetchedStandings, fetchedDate = VRSStandingsData._fetch(settings.updated, settings.datapointType)
		standings = fetchedStandings
		settings.updated = string.sub(fetchedDate, 1, 10) or settings.updated
	else
		Table.iter.forEachPair(props, function(key, value)
			if not string.match(key, '^%d+$') then
				return
			end

			local data = Json.parse(value)

			local opponent = Opponent.readOpponentArgs(Table.merge(data, {
				type = Opponent.team,
			}))

			data[1] = nil
			opponent.players = Array.map(Array.range(1, 5), FnUtil.curry(Opponent.readPlayerArgs, data))

			opponent.extradata = opponent.extradata or {}
			opponent.extradata.region = data.region
			opponent.extradata.subregion = data.subregion
			opponent.extradata.country = data.country

			table.insert(standings, {
				place = tonumber(key),
				points = tonumber(data.points),
				opponent = opponent
			})
		end)

		VRSStandingsData._store(settings.updated, settings.datapointType, standings)
	end

	Array.sortInPlaceBy(standings, Operator.property('place'))

	-- Filtering
	standings = Array.filter(standings, function(entry)
		local extradata = entry.opponent.extradata or {}

		if settings.filterType == 'region' then
			return extradata.region == settings.filterRegion
		end

		if settings.filterType == 'subregion' then
			return extradata.subregion == settings.filterSubregion
		end

		if settings.filterType == 'country' then
			local filterSet = {}
			for _, flag in ipairs(settings.filterCountry) do
				filterSet[flag] = true
			end
			local matchingPlayers = Array.filter(entry.opponent.players, function(player)
				return player ~= nil
					and player.flag ~= nil
					and filterSet[player.flag]
			end)
			return #matchingPlayers >= 3
		end

		return true
	end)

	if settings.fetchLimit then
		standings = Array.sub(standings, 1, settings.fetchLimit)
	end

	Array.forEach(standings, function(entry, index)
		entry.local_place = index
		if settings.filterType ~= 'none' then
			entry.global_place = entry.place
		end
	end)

	return standings, settings
end

---@private
---@param updated string
---@param datapointType string
---@param standings VRSStandingsStanding[]
function VRSStandingsData._store(updated, datapointType, standings)
	if Lpdb.isStorageDisabled() then
		return
	end

	local dataPoint = Lpdb.DataPoint:new{
		objectname = datapointType .. '_' .. updated,
		type = datapointType,
		name = 'Unofficial VRS (' .. updated .. ')',
		date = updated,
		extradata = standings
	}

	dataPoint:save()
end

---@private
---@param updated string
---@param datapointType string
---@return VRSStandingsStanding[]
---@return string
function VRSStandingsData._fetch(updated, datapointType)
	local conditions = Condition.Tree(BooleanOperator.all):add{
		Condition.Node(Condition.ColumnName('namespace'), Comparator.eq, 0),
	}

	if updated ~= 'latest' then
		conditions:add{
			Condition.Node(Condition.ColumnName('date'), Comparator.eq, updated)
		}
	end

	if datapointType == DATAPOINT_TYPE_MAIN then
		conditions:add{
			Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_MAIN)
		}
	elseif datapointType == DATAPOINT_TYPE_LIQUIPEDIA then
		conditions:add{
			Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_LIQUIPEDIA)
		}
	elseif datapointType == DATAPOINT_TYPE_PREDICTION then
		conditions:add{
			Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_PREDICTION)
		}
	else
		conditions:add(
			Condition.Util.anyOf(
				Condition.ColumnName('type'),
				{DATAPOINT_TYPE_LIVE, DATAPOINT_TYPE_MAIN}
			)
		)
	end

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions:toString(),
		query = 'extradata, date',
		order = 'date desc',
		limit = 1,
	})

	assert(data[1], 'No VRS data found for type "' .. datapointType .. '" on date "' .. updated .. '"')
	return data[1].extradata, data[1].date
end

return VRSStandingsData
