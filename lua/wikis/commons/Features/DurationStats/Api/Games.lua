---
-- @Liquipedia
-- page=Module:Features/DurationStats/Api/Games
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Lpdb = Lua.import('Module:Lpdb')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local QUERY_STRING = 'date, pagename, match2id, match2gameid, length, winner, vod'

local Games = {}

---Fetches games from LPDB.
---@param conditions string
---@param limit integer
---@param order string
---@return match2game[]
function Games.fetch(conditions, limit, order)
	---@type match2game[]
	local games = {}

	Lpdb.executeMassQuery('match2game', {
		query = QUERY_STRING,
		conditions = conditions,
		order = order,
	}, function(game)
		table.insert(games, game)
	end, limit)

	return games
end

---Fetches the match a game belongs to as a standard match.
---@param match2id string
---@return MatchGroupUtilMatch?
function Games.fetchMatch(match2id)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('opponent'), Comparator.neq, 'TBD'),
		ConditionNode(ColumnName('match2id'), Comparator.eq, match2id),
	}

	local record = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = 1,
		conditions = tostring(conditions),
	})[1]

	return record and MatchGroupUtil.matchFromRecord(record) or nil
end

return Games
