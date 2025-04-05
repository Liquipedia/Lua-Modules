---
-- @Liquipedia
-- wiki=commons
-- page=Module:CharacterStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lpdb = require('Module:Lpdb')
local Page = require('Module:Page')
local Table = require('Module:Table')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CharacterStats = {}

---@param args table
---@return match2game[]
function CharacterStats.fetchGames(args)
	local lpdbConditon = ConditionTree(BooleanOperator.all)

	local tournamentsConditon = ConditionTree(BooleanOperator.any)
	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament') do
		tournamentsConditon:add(ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(tournament)))
	end

	lpdbConditon:add(tournamentsConditon)
	lpdbConditon:add(ConditionNode(ColumnName('length'), Comparator.neq, ''))

	local games = {}
	Lpdb.executeMassQuery(
		'match2game',
		{conditions = lpdbConditon:toString(), query = 'match2id, length, extradata'},
		function (game) table.insert(games, game) end
	)
	return games
end

return CharacterStats
