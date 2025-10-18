---
-- @Liquipedia
-- page=Module:CharacterStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Logic = Lua.import('Module:Logic')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CharacterStatsGame: MatchGroupUtilGame
---@field matchOpponents standardOpponent[]

---@class CharacterStats
---@operator call(table): CharacterStats
---@field protected args table
---@field protected matchGroupsSpec MatchGroupsSpec
local CharacterStats = Class.new(
	---@param self self
	---@param args table
	function (self, args)
		self.args = args
		self.matchGroupsSpec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec()
	end
)

---@protected
---@return ConditionTree
function CharacterStats:buildConditions()
	local args = self.args
	local conditions = ConditionTree(BooleanOperator.all):add{
		TournamentStructure.getMatch2Filter(self.matchGroupsSpec),
		ConditionUtil.anyOf(ColumnName('liquipediatier'), Array.parseCommaSeparatedString(self.args.tier))
	}
	if args.sdate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, args.sdate))
	end
	if args.edate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.le, args.edate))
	end
	return conditions
end

---@param conditions AbstractConditionNode
---@return string[]
function CharacterStats:getMatchIds(conditions)
	---@type string[]
	return Array.map(mw.ext.LiquipediaDB.lpdb('match2', {
		limit = 5000,
		query = 'match2id',
		conditions = tostring(conditions),
		order = 'match2id asc'
	}), Operator.property('match2id'))
end

---@param matchIds string[]
---@return CharacterStatsGame[]
function CharacterStats:queryGames(matchIds)
	return Array.flatMap(matchIds, function (matchId)
		local matchOpponents = Array.map(
			mw.ext.LiquipediaDB.lpdb('match2opponents', {
				conditions = tostring(ConditionNode(ColumnName('match2id'), Comparator.eq, matchId)),
				order = 'match2opponentid asc',
			}),
			Opponent.fromMatch2Record
		)
		local games = Array.map(
			mw.ext.LiquipediaDB.lpdb('match2game', {
				conditions = tostring(ConditionTree(BooleanOperator.all):add{
					ConditionNode(ColumnName('match2id'), Comparator.eq, matchId),
					ConditionNode(ColumnName('winner'), Comparator.neq, ''),
				}),
				order = 'match2gameid asc',
			}),
			function (gameRecord)
				local game = MatchGroupUtil.gameFromRecord(gameRecord)
				---@cast game CharacterStatsGame
				game.matchOpponents = matchOpponents
				return game
			end
		)
		return games
	end)
end

---@protected
---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function CharacterStats:getTeamCharacters(game, opponentIndex)
	error('CharacterStats:getTeamCharacters() cannot be called directly and must be overridden.')
end

---@protected
---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string[]
function CharacterStats:getTeamBans(game, opponentIndex)
	error('CharacterStats:getTeamBans() cannot be called directly and must be overridden.')
end

---@protected
---@param game CharacterStatsGame
---@param opponentIndex integer
---@return string
function CharacterStats:getTeamSide(game, opponentIndex)
	error('CharacterStats:getTeamSide() cannot be called directly and must be overridden.')
end

return CharacterStats
