---
-- @Liquipedia
-- page=Module:PortalStatistics/PieChartBreakdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local Info = Lua.import('Module:Info', {loadData = true})
local Lpdb = Lua.import('Module:Lpdb')
local PrizepoolBreakdown = Lua.import('Module:PortalStatistics/PrizepoolBreakdown')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Box = Lua.import('Module:Widget/Basic/Box')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CURRENCY_FORMAT_OPTIONS = {dashIfZero = true, displayCurrencyCode = false, formatValue = true}
local TIMESTAMP = DateExt.getCurrentTimestamp()
local DATE = DateExt.toYmdInUtc(TIMESTAMP)
local MAX_QUERY_LIMIT = 5000
local US_DOLLAR = 'USD'
local TYPES = {'Online', 'Offline'}
local GAMES = Array.map(Array.extractValues(Info.games, Table.iter.spairs), function(value)
	return value.name
end)

local StatisticsPortal = {}

StatisticsPortal.prizepoolBreakdown = PrizepoolBreakdown.prizepoolBreakdown

---@param args table?
---@return VNode
function StatisticsPortal.pieChartBreakdown(args)
	args = args or {}
	args.height = args.height or 300
	args.width = args.width or 400
	args.hideKey = Logic.readBool(args.hideKey)
	args.detailedKey = Logic.readBool(args.detailedKey)
	args.multiGame = Logic.readBool(args.multiGame)
	args.multiMode = Logic.readBool(args.multiMode)

	local wrapperChildren = {
		Html.Div{
			css = {
				['padding-right'] = '5em',
				['font-size'] = '85%',
				['text-align'] = 'center',
			},
			children = {
				'Tournament Type',
				StatisticsPortal._getPieChartData(
					args, 'type', 'Mixed', TYPES
				),
			},
		},
	}

	if args.multiGame then
		local games = Array.map(StatisticsPortal._isTableOrSplitOrDefault(args.customGames, GAMES), function(game)
			return Game.toIdentifier{game = game, useDefault = false} or game
		end)
		table.insert(wrapperChildren, Html.Div{
			css = {
				['padding-right'] = '5em',
				['font-size'] = '85%',
				['text-align'] = 'center',
			},
			children = {
				'Game Breakdown',
				StatisticsPortal._getPieChartData(args, 'game', 'Other', games),
			},
		})
	end

	if args.multiMode then
		table.insert(wrapperChildren, Html.Div{
			css = {
				['padding-right'] = '5em',
				['font-size'] = '85%',
				['text-align'] = 'center',
			},
			children = {
				'Mode Breakdown',
				StatisticsPortal._getPieChartData(
					args, 'mode', 'Other', StatisticsPortal._isTableOrSplitOrDefault(args.customModes, {'Team'})
				),
			},
		})
	end

	if args.hideKey then
		return Html.Div{children = Box{children = wrapperChildren}}
	end

	if args.detailedKey then
		table.insert(wrapperChildren, Box{
			children = StatisticsPortal.prizepoolBreakdown(args),
		})
		return Html.Div{children = Box{children = wrapperChildren}}
	end

	local conditions = StatisticsPortal._returnBaseConditions()

	if args.year then
		conditions:add{ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('sortdate_year'), Comparator.eq, args.year),
			},
		}
	else
		conditions:add{ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('sortdate'), Comparator.lt, DATE),
			},
		}
	end

	if args.game then
		local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
	end

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'sum::prizepool',
		limit = MAX_QUERY_LIMIT,
		conditions = conditions:toString(),
		order = 'sortdate desc',
	})

	local summaryTable = TableWidgets.Table{
		children = {
			TableWidgets.TableHeader{children = TableWidgets.Row{
				children = TableWidgets.CellHeader{children = 'Total prize money awarded'}
			}},
			TableWidgets.TableBody{children = TableWidgets.Row{
				children = TableWidgets.Cell{
					attributes = {['data-sort-type'] = 'currency'},
					children = Html.B{children = Currency.display(
						US_DOLLAR, data[1].sum_prizepool or 0, CURRENCY_FORMAT_OPTIONS
					)}
				}
			}}
		}
	}

	table.insert(wrapperChildren, Box{
		paddingRight = '1em',
		children = summaryTable,
	})

	return Html.Div{children = Box{children = wrapperChildren}}
end

---@param args table
---@param groupBy string
---@param defaultValue string
---@param groupValues table
---@return Renderable
function StatisticsPortal._getPieChartData(args, groupBy, defaultValue, groupValues)
	table.insert(groupValues, defaultValue)
	defaultValue = string.lower(defaultValue or '')

	local prizes = {}
	for _, value in Table.iter.spairs(groupValues) do
		prizes[value:lower()] = {name = value, value = 0}
	end

	local LPDBConditions = StatisticsPortal._returnBaseConditions()
	LPDBConditions:add{ConditionNode(ColumnName('namespace'), Comparator.eq, 0)}

	if args.year then
		LPDBConditions:add{ConditionNode(ColumnName('sortdate_year'), Comparator.eq, args.year)}
	else
		LPDBConditions:add{ConditionNode(ColumnName('sortdate'), Comparator.lt, DATE)}
	end

	if args.game then
		local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
		LPDBConditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
	end

	local function parseTournament(data)
		local normValue = string.lower(data[groupBy] or '')
		if prizes[normValue] then
			prizes[normValue].value = prizes[normValue].value + data.prizepool
		else
			prizes[defaultValue].value = prizes[defaultValue].value + data.prizepool
		end
	end

	--Querying data
	local queryParameters = {
		conditions = LPDBConditions:toString(),
		query = 'prizepool, ' .. groupBy,
	}

	--Querying data
	Lpdb.executeMassQuery('tournament', queryParameters, parseTournament)

	Array.forEach(Array.extractValues(prizes), function(prize)
		prize.value = math.floor(prize.value + 0.5)
	end)

	if prizes[defaultValue].value == 0 then
		Table.extract(prizes, defaultValue)
	end

	local chartData = Array.map(Array.extractValues(groupValues), function(value)
		return prizes[value:lower()]
	end)

	if groupBy == 'game' and Logic.readBool(args.abbreviateGame) then
		chartData = Array.map(chartData, function(entry)
			entry.name = Game.abbreviation{game = entry.name, useDefault = false} or entry.name
			return entry
		end)
	elseif groupBy == 'game' then
		chartData = Array.map(chartData, function(entry)
			entry.name = Game.name{game = entry.name, useDefault = false} or entry.name
			return entry
		end)
	end

	return StatisticsPortal._drawPieChart(args, chartData)
end

---@param args table
---@param chartData table
---@return Renderable
function StatisticsPortal._drawPieChart(args, chartData)
	return Html.Div{
		class = 'table-responsive',
		children = mw.ext.Charts.piechart{
			size = {
				height = args.height,
				width = args.width
			},
			data = chartData
		}
	}
end


--[[
Section: Utility Functions
]]--

---@return ConditionTree
function StatisticsPortal._returnBaseConditions()
	return ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'cancelled')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'delayed')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'postponed')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.neq, '')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.neq, '0')}
end

---@param input string|table|nil
---@param default table?
---@return table
function StatisticsPortal._isTableOrSplitOrDefault(input, default)
	if type(input) == 'table' then
		return input
	elseif String.isEmpty(input) then
		return default or {}
	end
	return Array.parseCommaSeparatedString(input)
end

return Class.export(StatisticsPortal, {exports = {'pieChartBreakdown'}})
