---
-- @Liquipedia
-- page=Module:Features/DurationStats/Api/Tournaments
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Tier = Lua.import('Module:Tier/Utils')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local MATCH_QUERY_LIMIT = 5000

local Tournaments = {}

---Finds the tournaments of a tier (within an optional date range) and returns them as a match group spec.
---@param args table
---@return MatchGroupsSpec?
function Tournaments.getSpecFromTier(args)
	if Logic.isEmpty(args.tier) then return end
	local conditions = ConditionTree(BooleanOperator.all):add(Array.append({},
		ConditionNode(ColumnName('liquipediatier'), Comparator.eq, Tier.toIdentifier(args.tier)),
		args.sdate and ConditionNode(ColumnName('date'), Comparator.ge, args.sdate) or nil,
		args.edate and ConditionNode(ColumnName('date'), Comparator.le, args.edate) or nil
	))

	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = MATCH_QUERY_LIMIT,
		query = 'pagename',
		conditions = tostring(conditions),
		order = 'pagename asc',
		groupby = 'pagename asc'
	})

	local tournaments = Array.map(matches, Operator.property('pagename'))
	if Logic.isEmpty(tournaments) then return end

	return {matchGroupIds = {}, pageNames = {tournaments}}
end

return Tournaments
