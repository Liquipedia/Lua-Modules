---
-- @Liquipedia
-- page=Module:Widget/VRSStandings.lua
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
local Opponent = Lua.import('Module:Opponent')
local PlayerDisplay = Lua.import('Module:Player/Display')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')
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


local DATAPOINT_TYPE_LIVE = 'vrs_ranking_live'
local DATAPOINT_TYPE_MAIN = 'vrs_ranking'
local FOOTER_LINK = 'Valve_Regional_Standings'

---@class VRSStandings: Widget
---@operator call(table): VRSStandings
---@field props table<string|number, string>
local VRSStandings = Class.new(Widget)
VRSStandings.defaultProps = {
	title = 'VRS Standings',
	rankingType = 'live',
}

---@return Widget?
function VRSStandings:render()
	local standings, settings = self:_parse()

	local headerCells
	if settings.filterType ~= 'none' then
		headerCells = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Rank'},
			TableWidgets.CellHeader{children = 'Global Rank'},
			TableWidgets.CellHeader{children = 'Points'},
			TableWidgets.CellHeader{children = 'Team'}
		)
	else
		headerCells = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Rank'},
			TableWidgets.CellHeader{children = 'Points'},
			TableWidgets.CellHeader{children = 'Team'},
			TableWidgets.CellHeader{children = 'Region'}
		)
	end

	if not settings.mainpage then
		table.insert(headerCells, TableWidgets.CellHeader{children = 'Roster'})
	end

	local headerRow = TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{children = headerCells}
		}
	}
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
		titleName = settings.filterCountryDisplay
	end

	local title = HtmlWidgets.Div {
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

	local footer = Link {
		link = FOOTER_LINK,
		linktype = 'internal',
		children = {
			HtmlWidgets.Div {
				children = { 'See Rankings Page', Icon.makeIcon { iconName = 'goto' } },
				classes = { 'ranking-table__footer-button' },
			}
		},
	}

	if #standings == 0 then
		return HtmlWidgets.Div{
			children = {
				HtmlWidgets.B{ children = 'No teams found for the selected filter.' }
			},
			css = { padding = '12px' }
		}
	end

	local tableWidget = TableWidgets.Table{
		title = title,
		sortable = false,
		columns = columns,
		footer = settings.mainpage and footer or nil,
		css = settings.mainpage and { width = '100%' } or nil,
		children = {
			headerRow,
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

---@private
function VRSStandings:_parse()
	local props = self.props
	local rankingType = (props.rankingType == 'main') and 'main' or 'live'
	local datapointType = (rankingType == 'main') and DATAPOINT_TYPE_MAIN or DATAPOINT_TYPE_LIVE

	local settings = {
		title = props.title,
		shouldFetch = Logic.readBool(props.shouldFetch),
		fetchLimit = tonumber(props.fetchLimit),
		filterRegion = props.filterRegion,
		filterSubregion = props.filterSubregion,
		filterCountry = props.filterCountry,
		mainpage = Logic.readBool(props.mainpage),
		rankingType = rankingType,
		datapointType = datapointType,
	}

	if props.updated == 'latest' or not props.updated then
		settings.updated = VRSStandings._fetchLatestDate(datapointType)
	else
		settings.updated = DateExt.toYmdInUtc(props.updated)
	end

	-- Only one filter can be applied at once
	settings.filterType = 'none'

	if settings.filterRegion then
		settings.filterType = 'region'
	elseif settings.filterSubregion then
		settings.filterType = 'subregion'
	elseif settings.filterCountry then
		settings.filterType = 'country'
	end

	settings.filterCountries = nil
	settings.filterCountryDisplay = 'Filtered'

	if settings.filterCountry then
		local rawList = mw.text.split(settings.filterCountry, ',')
		local countrySet = {}

		for _, raw in ipairs(rawList) do
			countrySet[mw.text.trim(raw)] = true
		end

		settings.filterCountries = countrySet
		settings.filterCountryDisplay = #rawList > 1 and 'Filtered' or mw.text.trim(rawList[1])
	end

	---@type {points: number, opponent: standardOpponent}[]
	local standings = {}

	if settings.shouldFetch then
		standings = VRSStandings._fetch(settings.updated, settings.datapointType)
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
			opponent.players = Array.map(Array.range(1,5), FnUtil.curry(Opponent.readPlayerArgs, data))

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

	if settings.filterType ~= 'none' then
		for i, entry in ipairs(standings) do
			entry.global_place = i
		end
	end
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
			local matchingPlayers = Array.filter(entry.opponent.players, function(player)
				return player ~= nil
					and player.flag ~= nil
					and settings.filterCountries[player.flag] == true
			end)
			return #matchingPlayers >= 3
		end

		return true
	end)

	if settings.fetchLimit then
		standings = Array.sub(standings, 1, settings.fetchLimit)
	end

	for i, entry in ipairs(standings) do
		entry.place = i
	end

	return standings, settings
end

---@private
function VRSStandings._row(standing, mainpage)
	local extradata = standing.opponent.extradata or {}

	local cells
	if standing.global_place then
		cells = WidgetUtil.collect(
			TableWidgets.Cell{children = standing.place},
			TableWidgets.Cell{children = standing.global_place},
			TableWidgets.Cell{
				children = MathUtil.formatRounded{value = standing.points, precision = 1}
			},
			TableWidgets.Cell{
				children = OpponentDisplay.InlineTeamContainer{
					template = standing.opponent.template
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
				children = OpponentDisplay.InlineTeamContainer{
					template = standing.opponent.template
				}
			},
			TableWidgets.Cell{children = extradata.region or ''}
		)
	end

	if not mainpage then
		table.insert(cells,
			TableWidgets.Cell{
				children = Array.map(standing.opponent.players,function(player)
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
function VRSStandings._store(updated, datapointType, standings)
	if Lpdb.isStorageDisabled() then
		return
	end

	local dataPoint = Lpdb.DataPoint:new{
		objectname = datapointType .. '_' .. updated,
		type = datapointType,
		name = 'Inofficial VRS (' .. updated .. ')',
		date = updated,
		extradata = standings
	}

	dataPoint:save()
end

---@private
function VRSStandings._fetch(updated, datapointType)
	local conditions = Condition.Tree(BooleanOperator.all):add{
		Condition.Node(Condition.ColumnName('date'), Comparator.eq, updated),
		Condition.Node(Condition.ColumnName('namespace'), Comparator.eq, 0),
	}

	if datapointType == DATAPOINT_TYPE_MAIN then
		conditions:add{
			Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_MAIN),
		}
	else
		conditions:add{
			Condition.Tree(BooleanOperator.any):add{
				Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_LIVE),
				Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_MAIN),
			}
		}
	end

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions:toString(),
		query = 'extradata',
		limit = 1,
	})

	assert(data[1], 'No VRS data found for type "' .. datapointType .. '" on date "' .. updated .. '"')
	return data[1].extradata
end

---@private
function VRSStandings._fetchLatestDate(datapointType)
	local conditions = Condition.Tree(BooleanOperator.all):add{
		Condition.Node(Condition.ColumnName('namespace'), Comparator.eq, 0),
	}

	if datapointType == DATAPOINT_TYPE_MAIN then
		conditions:add{
			Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_MAIN),
		}
	else
		conditions:add{
			Condition.Tree(BooleanOperator.any):add{
				Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_LIVE),
				Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE_MAIN),
			}
		}
	end

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions:toString(),
		query = 'date',
		order = 'date desc',
		limit = 1,
	})

	assert(data[1], 'No VRS data found for type "' .. datapointType .. '"')
	return DateExt.toYmdInUtc(DateExt.parseIsoDate(data[1].date))
end

return VRSStandings
