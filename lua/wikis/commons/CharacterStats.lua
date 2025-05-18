---
-- @Liquipedia
-- wiki=commons
-- page=Module:CharacterStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local CharacterStats = {}

---@param match2Id string
---@return standardOpponent[]
local getOpponents = FnUtil.memoize(function (match2Id)
	local matchData = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(ConditionNode(ColumnName('match2id'), Comparator.eq, match2Id)),
		query = 'match2opponents, date, bestof',
		limit = 1
	})[1]
	return Array.map(matchData.match2opponents, function (record, index)
		return MatchGroupUtil.opponentFromRecord(matchData, record, index)
	end)
end)

---@param match2id string
---@param opponentIndex integer
---@return standardOpponent
local function getOpponent(match2id, opponentIndex)
	return getOpponents(match2id)[opponentIndex]
end

---@param args table
---@return match2game[]
function CharacterStats.fetchGames(args)
	local lpdbCondition = ConditionTree(BooleanOperator.all)

	local tournamentsConditon = ConditionTree(BooleanOperator.any)
	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament') do
		tournamentsConditon:add(ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(tournament)))
	end

	lpdbCondition:add(tournamentsConditon)
	lpdbCondition:add(ConditionNode(ColumnName('length'), Comparator.neq, ''))

	local games = mw.ext.LiquipediaDB.lpdb('match2game', {
		conditions = tostring(lpdbCondition),
		query = 'date, match2id, length, extradata, winner',
		order = 'date asc',
		limit = 5000
	})
	return games
end

---@param games match2game[]
function CharacterStats.processGames(games)
	---@type string[][]
	local picks = {{}, {}}
	---@type string[][]
	local bans = {{}, {}}
end

return CharacterStats
