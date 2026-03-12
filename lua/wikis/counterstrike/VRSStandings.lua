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


local DATAPOINT_TYPE = 'vrs_ranking'

---@class VRSStandings: Widget
---@operator call(table): VRSStandings
---@field props table<string|number, string>
local VRSStandings = Class.new(Widget)
VRSStandings.defaultProps = {
	title = 'VRS Standings',
}

---@return Widget?
function VRSStandings:render()
	local standings, settings = self:_parse()

	local headerRow = TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Rank'},
			TableWidgets.CellHeader{children = 'Points'},
			TableWidgets.CellHeader{children = 'Team'},
			TableWidgets.CellHeader{children = 'Roster'}
		)}
	}}

	local title = HtmlWidgets.Div {
		children = {
			HtmlWidgets.Div {
				children = {
					HtmlWidgets.B { children = 'Unofficial VRS' },
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

	return TableWidgets.Table{
		title = title,
		sortable = false,
		columns = WidgetUtil.collect(
			{
				align = 'right',
				sortType = 'number'
			},
			{
				align = 'right',
				sortType = 'number',
			},
			{
				align = 'left'
			},
			{
				align = 'left'
			}
		),
		children = {
			headerRow,
			TableWidgets.TableBody{children = Array.map(standings, VRSStandings._row)}
		},
	}
end

---@private
---@return {place: number, points: number, opponent: standardOpponent}[]
---@return {title: string, updated: string, shouldStore: boolean, shouldFetch: boolean}
function VRSStandings:_parse()
	local props = self.props
	local settings = {
		title = props.title,
		updated = DateExt.toYmdInUtc(props.updated or DateExt.getCurrentTimestamp()),
		shouldFetch = Logic.readBool(props.shouldFetch),
		fetchLimit = tonumber(props.fetchLimit)
	}

	---@type {points: number, opponent: standardOpponent}[]
	local standings = {}

	if settings.shouldFetch then
		standings = self._fetch(settings.updated, settings.fetchLimit)
	else
		Table.iter.forEachPair(self.props, function(key, value)
			if not string.match(key, '^%d+$') then
				return
			end

			local data = Json.parse(value)
			local opponent = Opponent.readOpponentArgs(Table.merge(data, {
				type = Opponent.team,
			}))

			-- Remove template from data to not confuse it with first player
			data[1] = nil
			opponent.players = Array.map(Array.range(1, 5), FnUtil.curry(Opponent.readPlayerArgs, data))

			table.insert(standings, {
				place = tonumber(key),
				points = tonumber(data.points),
				opponent = opponent
			})
		end)

		self._store(settings.updated, standings)
	end

	Array.sortInPlaceBy(standings, Operator.property('place'))

	return standings, settings
end

---@private
---@param standing {place: number, points: number, opponent: standardOpponent}
---@return Widget
function VRSStandings._row(standing)
	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.Cell{
			children = standing.place,
		},
		TableWidgets.Cell{
			children = MathUtil.formatRounded{value = standing.points, precision = 1}
		},
		TableWidgets.Cell{
			children = OpponentDisplay.InlineTeamContainer{
				template = standing.opponent.template
			}
		},
		TableWidgets.Cell{
			children = Array.map(standing.opponent.players, function(player)
				return HtmlWidgets.Span{
					css = {
						display = "inline-block",
						width = "160px"
					},
					children = PlayerDisplay.InlinePlayer({player = player})
				}
			end),
		}
	)}
end

---@private
---@param updated string
---@param standings {place: number, points: number, opponent: standardOpponent}[]
function VRSStandings._store(updated, standings)
	if Lpdb.isStorageDisabled() then
		return
	end
	local dataPoint = Lpdb.DataPoint:new{
		objectname = 'vrs_' .. updated,
		type = DATAPOINT_TYPE,
		name = 'Inofficial VRS (' .. updated .. ')',
		date = updated,
		extradata = standings
	}
	dataPoint:save()
end

---@private
---@param updated string
---@param fetchLimit integer
---@return {place: number, points: number, opponent: standardOpponent}[]
function VRSStandings._fetch(updated, fetchLimit)
	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = Condition.Tree(BooleanOperator.all):add{
			Condition.Node(Condition.ColumnName('type'), Comparator.eq, DATAPOINT_TYPE),
			Condition.Node(Condition.ColumnName('date'), Comparator.eq, updated),
		}:toString(),
		query = 'extradata',
		limit = 1,
	})

	assert(data[1], 'No VRS data found')
	return Array.sub(data[1].extradata, 1, fetchLimit)
end

return VRSStandings
