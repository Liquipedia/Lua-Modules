---
-- @Liquipedia
-- page=Module:Features/DurationStats/Lib/Conditions
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Conditions = {}

---Builds the match2game conditions: only played games with a winner and a length, within the given tournaments.
---@param spec MatchGroupsSpec
---@return ConditionTree
function Conditions.build(spec)
	return ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('winner'), Comparator.neq, ''),
		ConditionNode(ColumnName('length'), Comparator.neq, ''),
		ConditionNode(ColumnName('status'), Comparator.neq, 'notplayed'),
		TournamentStructure.getPageNamesFilter('bracket', Array.flatten(spec.pageNames)),
	}
end

return Conditions
