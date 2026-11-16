---
-- @Liquipedia
-- page=Module:PortalStatistics/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

-- Only import lightweight modules here, as this module is used by all of the PortalStatistics modules.
-- Everything else should be imported by the module that needs it.
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CURRENT_YEAR = DateExt.getYearOf()

--- Helpers that are shared between the PortalStatistics modules
---@class PortalStatisticsUtil
local Util = {}

---Names of all games of the wiki
---@type string[]
Util.GAMES = Array.map(Array.extractValues(Info.games, Table.iter.spairs), function(value)
	return value.name
end)

---@param input string|table|nil
---@param default table?
---@return table
function Util.isTableOrSplitOrDefault(input, default)
	if type(input) == 'table' then
		return input
	elseif String.isEmpty(input) then
		return default or {}
	end
	return Array.parseCommaSeparatedString(input)
end

---Executes a LPDB query using Lpdb.executeMassQuery and returns all rows.
---@param tableName string Name of the table
---@param parameters table Query parameters
---@return table
function Util.massQuery(tableName, parameters)
	local data = {}

	Lpdb.executeMassQuery(tableName, parameters, function (item)
		table.insert(data, item)
	end, parameters.limit)

	return data
end

---Conditions to only include tournaments that have a prizepool and took place.
---@return ConditionTree
function Util.returnBaseConditions()
	return ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'cancelled')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'delayed')}
		:add{ConditionNode(ColumnName('status'), Comparator.neq, 'postponed')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.neq, '')}
		:add{ConditionNode(ColumnName('prizepool'), Comparator.neq, '0')}
end

---Returns the years that are displayed (`customYears` or all) and all years, starting at `args.startYear`.
---Sets `args.startYear` if it is not set.
---@param args table
---@return table, table
function Util.returnCustomYears(args)
	args.startYear = tonumber(args.startYear) or Info.startYear
	local defaultYearTable = Array.range(args.startYear, CURRENT_YEAR)
	if String.isNotEmpty(args.customYears) then
		local yearTable = Array.map(
			Util.isTableOrSplitOrDefault(args.customYears),
			function(year)
				return tonumber(year)
			end
		)
		table.insert(yearTable, CURRENT_YEAR)
		return yearTable, defaultYearTable
	end
	return defaultYearTable, defaultYearTable
end

---@param prevYear number
---@param yearValue number
---@return string|number
function Util.returnCustomYearText(prevYear, yearValue)
	return (prevYear == yearValue) and yearValue or
		'\'' .. (string.sub(prevYear, 3, 4) .. '-' .. string.sub(yearValue, 3, 4))
end

---Cell for the game column of the coverage tables, `Total` if no game is given.
---@param args table
---@param parameters table
---@param isHeaderRow boolean
---@return Renderable
function Util.returnGameCell(args, parameters, isHeaderRow)
	-- Imported here, as not every module using this Util needs the table widgets
	local TableWidgets = Lua.import('Module:Widget/Table2/All')
	local CellComponent = isHeaderRow and TableWidgets.CellHeader or TableWidgets.Cell
	local text = (Logic.readBool(args.multiGame) and not parameters.game) and 'Total' or parameters.game
	return CellComponent{children = text}
end

return Util
