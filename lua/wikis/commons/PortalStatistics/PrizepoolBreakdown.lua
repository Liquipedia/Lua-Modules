---
-- @Liquipedia
-- page=Module:PortalStatistics/PrizepoolBreakdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Currency = Lua.import('Module:Currency')
local Count = Lua.import('Module:Count')
local DateExt = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local Info = Lua.import('Module:Info', {loadData = true})
local Math = Lua.import('Module:MathUtil')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
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
local CURRENT_YEAR = DateExt.getYearOf()
local DATE = DateExt.toYmdInUtc(TIMESTAMP)
local MAX_QUERY_LIMIT = 5000
local US_DOLLAR = 'USD'

local StatisticsPortal = {}


---@param args table?
---@return Renderable
function StatisticsPortal.prizepoolBreakdown(args)
	args = args or {}
	args.showAverage = Logic.readBool(args.showAverage)
	args.startYear = tonumber(args.startYear) or Info.startYear

	local yearTable, defaultYearTable = StatisticsPortal._returnCustomYears(args)
	local rowLimit = Math.round(((Logic.readBool(args.showAverage) and 1 or 0) + 1 + Table.size(yearTable)) / 2)

	local tables = {}
	local headerCells = {}
	local resultCells = {}

	local function finalizeTable()
		table.insert(tables, TableWidgets.Table{
			caption = 'Prize Money Awarded',
			children = {
				TableWidgets.TableHeader{children = TableWidgets.Row{children = headerCells}},
				TableWidgets.TableBody{children = TableWidgets.Row{children = resultCells}}
			}
		})
		headerCells = {}
		resultCells = {}
	end

	local prizepoolSum = 0
	local prevYear = args.startYear
	local colIndex = 1

	for _, yearValue in pairs(defaultYearTable) do
		local conditions = StatisticsPortal._returnBaseConditions()

		if args.game then
			local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
			conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
		end

		conditions:add{ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('sortdate_year'), Comparator.eq, yearValue)
			}
		}

		local data = mw.ext.LiquipediaDB.lpdb('tournament', {
				query = 'sum::prizepool',
				limit = MAX_QUERY_LIMIT,
				conditions = conditions:toString(),
				order = 'sortdate desc',
			}
		)

		prizepoolSum = prizepoolSum + (tonumber(data[1].sum_prizepool) or 0)

		if Array.any(Array.extractValues(yearTable), function(value) return value == yearValue end) then
			table.insert(headerCells, TableWidgets.CellHeader{
				children = StatisticsPortal._returnCustomYearText(prevYear, yearValue)
			})
			table.insert(resultCells, TableWidgets.Cell{
				children = Currency.display(US_DOLLAR, prizepoolSum or 0, CURRENCY_FORMAT_OPTIONS)
			})
			prizepoolSum = 0
			prevYear = yearValue + 1
			colIndex = colIndex + 1
		end

		if colIndex > rowLimit and rowLimit > 8 then
			colIndex = 1
			finalizeTable()
		end
	end

	local conditions = StatisticsPortal._returnBaseConditions()

	if args.game then
		local gameIdentifier = Game.toIdentifier{game = args.game, useDefault = false} or args.game
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, gameIdentifier)}
	end

	conditions:add{ConditionTree(BooleanOperator.all):add{
			ConditionNode(ColumnName('sortdate'), Comparator.lt, DATE)
		},
	}

	local totalData = mw.ext.LiquipediaDB.lpdb('tournament', {
			query = 'sum::prizepool',
			limit = MAX_QUERY_LIMIT,
			conditions = conditions:toString(),
			order = 'sortdate desc',
		}
	)
	local totalPrizePool = tonumber(totalData[1].sum_prizepool) or 0

	table.insert(headerCells, TableWidgets.CellHeader{children = 'Total'})
	table.insert(resultCells, TableWidgets.Cell{
		children = Html.B{children = Currency.display(US_DOLLAR, totalPrizePool, CURRENCY_FORMAT_OPTIONS)}
	})

	if Logic.readBool(args.showAverage) then
		table.insert(headerCells, TableWidgets.CellHeader{
			children = Html.Abbr{title = 'Average Prizepool per Tournament', children = 'AVG PPT'}
		})
		table.insert(resultCells, TableWidgets.Cell{
			children = Html.B{children = Currency.display(
				US_DOLLAR, totalPrizePool / (Count.tournaments() or 1), CURRENCY_FORMAT_OPTIONS
			)}
		})
	end

	finalizeTable()

	local wrapperChildren = {}
	for index, tableWidget in ipairs(tables) do
		if index > 1 then
			table.insert(wrapperChildren, Html.Br{})
		end
		table.insert(wrapperChildren, tableWidget)
	end

	return Html.Div{children = wrapperChildren}
end

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

---@param args table
---@return table, table
function StatisticsPortal._returnCustomYears(args)
	args.startYear = tonumber(args.startYear) or Info.startYear
	local yearTable
	local defaultYearTable = Array.range(args.startYear, CURRENT_YEAR)
	if String.isNotEmpty(args.customYears) then
		yearTable = Array.map(
			StatisticsPortal._isTableOrSplitOrDefault(args.customYears),
			function(tier)
				return tonumber(tier)
			end
		)
		table.insert(yearTable, CURRENT_YEAR)
		return yearTable, defaultYearTable
	else
		return defaultYearTable, defaultYearTable
	end
end

---@param prevYear number
---@param yearValue number
---@return string|number
function StatisticsPortal._returnCustomYearText(prevYear, yearValue)
	return (prevYear == yearValue) and yearValue or
		'\'' .. (string.sub(prevYear, 3, 4) .. '-' .. string.sub(yearValue, 3, 4))
end

return Class.export(StatisticsPortal, {exports = {'prizepoolBreakdown'}})
