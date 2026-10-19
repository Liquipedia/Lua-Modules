---
-- @Liquipedia
-- page=Module:Features/DurationStats/Lib/Conditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DATE_ONLY_PATTERN = '^%d%d%d%d%-%d%d%-%d%d$'
local END_OF_DAY = ' 23:59:59'

local Conditions = {}

---Builds the match2game conditions: only played games with a winner and a length, within the given tournaments
---and (optionally) within the given date range.
---@param spec MatchGroupsSpec
---@param sdate string?
---@param edate string?
---@return ConditionTree
function Conditions.build(spec, sdate, edate)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('winner'), Comparator.neq, ''),
		ConditionNode(ColumnName('length'), Comparator.neq, ''),
		ConditionNode(ColumnName('status'), Comparator.neq, 'notplayed'),
		TournamentStructure.getPageNamesFilter('bracket', Array.flatten(spec.pageNames)),
	}

	if Logic.isNotEmpty(sdate) then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, sdate))
	end

	if Logic.isNotEmpty(edate) then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.le, Conditions._endOfDay(edate)))
	end

	return conditions
end

---A date without a time (e.g. 2026-05-10) should include the games played during that whole day.
---@private
---@param date string
---@return string
function Conditions._endOfDay(date)
	if date:match(DATE_ONLY_PATTERN) then
		return date .. END_OF_DAY
	end
	return date
end

return Conditions
