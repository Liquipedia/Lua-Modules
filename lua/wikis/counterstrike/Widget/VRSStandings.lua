---
-- @Liquipedia
-- page=Module:Widget/VRSStandings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Table = Lua.import('Module:Table')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local Condition = Lua.import('Module:Condition')
local BooleanOperator = Condition.BooleanOperator
local Comparator = Condition.Comparator

local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Icon')

local DATAPOINT_TYPE_MAIN = 'vrs_ranking'
local DATAPOINT_TYPE_LIVE = 'vrs_ranking_live'
local DATAPOINT_TYPE_LIQUIPEDIA = 'vrs_ranking_liquipedia'
local DATAPOINT_TYPE_PREDICTION = 'vrs_ranking_prediction'
local FOOTER_LINK = 'Valve_Regional_Standings'

---@class VRSStandings: Widget
---@operator call(table): VRSStandings
---@field props table<string|number, string>
local VRSStandings = Class.new(Widget)
VRSStandings.defaultProps = {
    title = 'VRS Standings',
    datapointType = DATAPOINT_TYPE_LIVE,
}

---@return Widget?
local function buildHeaderCells(settings)
	if settings.filterType ~= 'none' then
		local cells = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Rank'},
			TableWidgets.CellHeader{children = 'Global Rank'},
			TableWidgets.CellHeader{children = 'Points'},
			TableWidgets.CellHeader{children = 'Team'}
		)
		if not settings.mainpage then
			table.insert(cells, TableWidgets.CellHeader{children = 'Roster'})
		end
		return cells
	else
		local cells = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Rank'},
			TableWidgets.CellHeader{children = 'Points'},
			TableWidgets.CellHeader{children = 'Team'},
			TableWidgets.CellHeader{children = 'Region'}
		)
		if not settings.mainpage then
			table.insert(cells, TableWidgets.CellHeader{children = 'Roster'})
		end
		return cells
	end
end

local function buildHeaderRow(settings)
	return TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{children = buildHeaderCells(settings)}
		}
	}
end

local function buildColumns(settings)
	local columns
	if settings.filterType ~= 'none' then
		columns = WidgetUtil.collect(
			{align = 'center', sortType = 'number'},
			{align = 'center', sortType = 'number'},
			{align = 'center', sortType = 'number'},
			{align = 'left'}
		)
	else
		columns = WidgetUtil.collect(
			{align = 'center', sortType = 'number'},
			{align = 'center', sortType = 'number'},
			{align = 'left'},
			{align = 'center'}
		)
	end
	if settings.mainpage then
		for _, col in ipairs(columns) do
			col.width = (100 / #columns) .. '%'
		end
	end
	if not settings.mainpage then
		table.insert(columns, {align = 'left'})
	end
	return columns
end

local function buildTitle(settings)
	local regionMap = {
		AS = 'Asia',
		AM = 'Americas',
		EU = 'Europe'
	}
	local titleName = 'Global'
	if settings.filterType == 'region' then
		titleName = regionMap[settings.filterRegion] or settings.filterRegion
	elseif settings.filterType == 'subregion' then
		titleName = 'Subregion'
	elseif settings.filterType == 'country' then
		titleName = settings.filterCountryDisplay or 'Country'
	end
	return HtmlWidgets.Div {
		children = {
			HtmlWidgets.Div {
				children = {
					HtmlWidgets.B { children = 'Unofficial ' .. titleName .. ' VRS' },
					HtmlWidgets.Span { children = 'Last updated: ' .. settings.updated }
				},
				classes = { 'ranking-table__top-row-text' }
			},
			HtmlWidgets.Div {
				children = {
					HtmlWidgets.Span { children = 'Data by Liquipedia' },
				},
				classes = { 'ranking-table__top-row-logo-container' }
			}
		},
		classes = { 'ranking-table__top-row' },
	}
end

local function buildFooter()
	return Link {
		link = FOOTER_LINK,
		linktype = 'internal',
		children = {
			HtmlWidgets.Div {
				children = { 'See Rankings Page', Icon.makeIcon { iconName = 'goto' } },
				classes = { 'ranking-table__footer-button' },
			}
		},
	}
end

function VRSStandings:render()
	local standings, settings = self:_parse()

	if #standings == 0 then
		return HtmlWidgets.Div{
			children = {
				HtmlWidgets.B{ children = 'No teams found for the selected filter.' }
			},
			css = { padding = '12px' }
		}
	end

	local tableWidget = TableWidgets.Table{
		title = buildTitle(settings),
		sortable = false,
		columns = buildColumns(settings),
		footer = settings.mainpage and buildFooter() or nil,
		css = settings.mainpage and { width = '100%' } or nil,
		children = {
			buildHeaderRow(settings),
			TableWidgets.TableBody{
				children = Array.map(standings, function(entry)
					return VRSStandings._row(entry, settings.mainpage)
				end)
			}
		},
	}

	if settings.mainpage then
		return HtmlWidgets.Div{
			css = { width = '100%' },
			children = { tableWidget }
		}
	else
		return tableWidget
	end
end

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

---@private
---@return VRSStandingsStanding[]
---@return VRSStandingsSettings

function VRSStandings:_parse()
    local props = self.props
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
		local fetchedStandings, fetchedDate = VRSStandings._fetch(settings.updated, settings.datapointType)
		standings = fetchedStandings
		settings.updated = string.sub(fetchedDate, 1, 10) or settings.updated
	else
		Table.iter.forEachPair(self.props, function(key, value)
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

			table.insert(standings,{
				place = tonumber(key),
				points = tonumber(data.points),
				opponent = opponent
			})
		end)

		VRSStandings._store(settings.updated, settings.datapointType, standings)
	end

	Array.sortInPlaceBy(standings, Operator.property('place'))

	-- filtering
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
					and filterSet[player.flag] == true
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
---@param standing VRSStandingsStanding
---@param mainpage boolean
---@return Widget
function VRSStandings._row(standing, mainpage)
	local extradata = standing.opponent.extradata or {}

	local cells
	if standing.global_place then
		cells = WidgetUtil.collect(
			TableWidgets.Cell{children = standing.local_place},
			TableWidgets.Cell{children = standing.global_place},
			TableWidgets.Cell{
				children = MathUtil.formatRounded{value = standing.points, precision = 1}
			},
			TableWidgets.Cell{
				children = OpponentDisplay.InlineOpponent{
					opponent = standing.opponent
				}
			}
		)
	else
		cells = WidgetUtil.collect(
			TableWidgets.Cell{children = standing.place},
			TableWidgets.Cell{
				children = MathUtil.formatRounded{value = standing.points, precision = 1}
			},
			TableWidgets.Cell{
				children = OpponentDisplay.InlineOpponent{
					opponent = standing.opponent
				}
			},
			TableWidgets.Cell{children = extradata.region or ''}
		)
	end

	if not mainpage then
		table.insert(cells,
			TableWidgets.Cell{
				children = Array.map(standing.opponent.players, function(player)
					return HtmlWidgets.Span{
						css = {display="inline-block", width="160px"},
						children = PlayerDisplay.InlinePlayer({player = player})
					}
				end)
			}
		)
	end

	return TableWidgets.Row{children = cells}
end

---@private
---@param updated string
---@param datapointType string
---@param standings VRSStandingsStanding[]
function VRSStandings._store(updated, datapointType, standings)
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
function VRSStandings._fetch(updated, datapointType)
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

return VRSStandings
