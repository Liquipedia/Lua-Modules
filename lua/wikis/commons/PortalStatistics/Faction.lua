---
-- @Liquipedia
-- page=Module:PortalStatistics/Faction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Lpdb = require('Module:Lpdb')
local Medals = require('Module:Medals')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@type integer[]
local TIERS = {}
for tier in Tier.iterate('tiers') do
	table.insert(TIERS, tonumber(tier))
end

---@type string[]
local TIER_DISPLAYS = Array.map(TIERS, function(tier)
	return Tier.toName(tier)
end)

local Statistics = {}

---@param props {series: table[], height: number?, width: number?, legend: string[]?,
---xAxis: string?, yAxis: string?, xAxisData: string[]}
---@return VNode
local makeBarChart = function(props)
	local series = Array.map(props.series, function(data)
		return Table.merge({type = 'bar', emphasis = {focus = 'series'}}, data)
	end)

	local barChart = mw.ext.Charts.chart{
		grid = {
			left = '15%',
			right = '12%',
			top = '15%',
			bottom = '10%'
		},
		size = {
			height = props.height,
			width = props.width,
		},
		tooltip = {
			trigger = 'axis',
		},
		legend = props.legend,
		xAxis = {
			axisLabel = {rotate = 0},
			axisTick = {alignWithLabel = true},
			data = props.xAxisData,
			name = props.xAxis,
			type = 'category',
		},
		yAxis = {
			name = props.yAxis,
			type = 'value'
		},
		series = series,
	}

	return Html.Div{
		classes = {'table-responsive'},
		children = barChart,
	}
end

---@param frame Frame
---@return VNode
function Statistics.factionWins(frame)
	local args = Arguments.getArgs(frame)

	local tiers = Array.append(TIERS, 'total')
	local tierDisplays = Array.append(TIER_DISPLAYS, 'Total')

	local data = {}
	Array.forEach(Faction.coreFactions, function(faction)
		data[faction] = {
			{total = 0}, -- place 1
			{total = 0}, -- place 2
		}
	end)

	---@param placement placement
	local processData = function(placement)
		local place = tonumber(placement.placement)
		if not place then return end
		local players = placement.opponentplayers or {}
		local faction = Faction.read(players.p1faction)
		local tier = tonumber(placement.liquipediatier)
		if not tier then return end
		if not data[faction] then return end

		data[faction][place] = data[faction][place] or {total = 0}
		data[faction][place][tier] = (data[faction][place][tier] or 0) + 1
		data[faction][place].total = data[faction][place].total + 1
	end

	local startDate = DateExt.readTimestampOrNil(args.sdate)
	local endDate = DateExt.readTimestampOrNil(args.edate) or DateExt.getCurrentTimestamp()

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Charity', 'Qualifier'}),
		ConditionUtil.anyOf(ColumnName('placement'), {1, 2}),
		ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.solo),
		ConditionNode(ColumnName('date'), Comparator.le, endDate),
		startDate and ConditionNode(ColumnName('date'), Comparator.ge, startDate) or nil,
	}

	Lpdb.executeMassQuery('placement', {
		conditions = tostring(conditions),
		order = 'liquipediatier desc',
		limit = 5000,
		query = 'liquipediatier, placement, opponentplayers',
	}, processData)

	local chartData = Array.map(Faction.coreFactions, function(faction)
		return {
			name = Faction.toName(faction),
			data = Array.map(tiers, function(tier)
				return data[faction][1][tier] or 0
			end),
		}
	end)

	local headerRow2Elements = {}
	Array.forEach(tiers, function()
		Array.appendWith(headerRow2Elements,
			TableWidgets.CellHeader{children = Medals.display{medal = 1}},
			TableWidgets.CellHeader{children = Medals.display{medal = 2}}
		)
	end)

	local header = {
		TableWidgets.Row{
			children = WidgetUtil.collect(
				TableWidgets.CellHeader{rowspan = 2},
				Array.map(tierDisplays, function(tier)
					return TableWidgets.CellHeader{colspan = 2, children = tier, align = 'center'}
				end)
			),
		},
		TableWidgets.Row{children = headerRow2Elements},
	}

	local makeRow = function(faction)
		return TableWidgets.Row{
			children = WidgetUtil.collect(
				TableWidgets.Cell{children = Faction.Icon{faction = faction}},
				Array.map(tiers, function(tier)
					return {
						TableWidgets.Cell{children = data[faction][1][tier] or '-'},
						TableWidgets.Cell{children = data[faction][2][tier] or '-'},
					}
				end)
			)
		}
	end

	local tableDisplay = TableWidgets.Table{
		sortable = true,
		columns = WidgetUtil.collect(
			{align = 'left'},
			Array.rep({align = 'right'}, 2 * #tiers)
		),
		children = {
			TableWidgets.TableHeader{children = header},
			TableWidgets.TableBody{children = Array.map(Faction.coreFactions, makeRow)},
		},
	}

	return Html.Fragment{
		children = {
			tableDisplay,
			Html.H3{children = 'Wins per Race and Liquipediatier'},
			makeBarChart{
				xAxisData = tierDisplays,
				series = chartData,
				width = 900,
				height = 300,
				legend = Array.map(Faction.coreFactions, function(faction) return Faction.toName(faction) end),
			},
		}
	}
end

---@param frame Frame
---@return VNode
function Statistics.tournaments(frame)
	local args = Arguments.getArgs(frame)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Charity', 'Qualifier'}),
		ConditionNode(ColumnName('enddate'), Comparator.neq, DateExt.defaultDate),
		ConditionNode(ColumnName('enddate'), Comparator.le, DateExt.getCurrentTimestamp()),
	}

	if args.year then
		local year = args.year
		assert(not year or year:match('^%d%d%d%d$'), args.year .. ' is not a valid year')
		conditions:add(ConditionNode(ColumnName('enddate_year'), Comparator.eq, year))
	end

	---@param date string
	---@return string|integer?
	local getDateGroup = function(date)
		local timestamp = DateExt.readTimestampOrNil(date)
		if not timestamp then return end
		if not args.year then
			return DateExt.formatTimestamp('Y', timestamp)
		end
		return tonumber(DateExt.formatTimestamp('n', timestamp))
	end

	local data = {}

	---@param tournament tournament
	local processData = function(tournament)
		local tier = tonumber(tournament.liquipediatier)
		if not tier then return end

		local dateGroup = getDateGroup(tournament.enddate)
		if not dateGroup then return end

		data[dateGroup] = data[dateGroup] or Table.map(TIERS, function(key, tierValue)
			return tierValue, 0
		end)

		data[dateGroup][tier] = data[dateGroup][tier] + 1
	end

	Lpdb.executeMassQuery('tournament', {
		conditions = tostring(conditions),
		query = 'liquipediatier, enddate',
		order = 'enddate asc',
		limit = 5000,
	}, processData)

	local dateGroups = Array.extractKeys(data)
	table.sort(dateGroups)

	local chartData = Array.map(TIERS, function(tier, tierIndex)
		return {
			name = TIER_DISPLAYS[tierIndex],
			data = Array.map(dateGroups, function(dateGroup)
				return data[dateGroup][tier]
			end)
		}
	end)

	if args.year then
		dateGroups = Array.map(dateGroups, function(monthIndex)
			return DateExt.formatTimestamp('M', DateExt.readTimestamp{
				year = 1970,
				month = monthIndex,
				day = 1,
			} --[[@as integer]])
		end)
	end

	return makeBarChart{
		xAxisData = dateGroups,
		series = chartData,
		width = 1200,
		height = 300,
		xAxis = args.year and 'Month' or 'Year',
		yAxis = 'Tournaments recorded',
		legend = TIER_DISPLAYS,
	}
end

return Statistics
