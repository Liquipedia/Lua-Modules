---
-- @Liquipedia
-- page=Module:CharacterStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

---@class CharacterStatsGame: MatchGroupUtilGame
---@field matchOpponents standardOpponent[]

---@alias CharacterAppearanceStats {pick: integer, win: integer, loss: integer}

---@class CharacterStatistic
---@field name string
---@field side table<string, {win: integer, loss: integer}> key is side
---@field total CharacterAppearanceStats
---@field bans integer
---@field playedWith table<string, CharacterAppearanceStats> key is character name
---@field playedVs table<string, CharacterAppearanceStats> key is character name
---@field playedBy table<string, CharacterAppearanceStats> key is opponent name

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
	return Array.unique(Array.map(mw.ext.LiquipediaDB.lpdb('match2', {
		limit = 5000,
		query = 'match2id',
		conditions = tostring(conditions),
		order = 'match2id asc'
	}), Operator.property('match2id')))
end

---@param matchIds string[]
---@return CharacterStatsGame[]
function CharacterStats:queryGames(matchIds)
	return Array.flatMap(matchIds, function (matchId)
		local matchOpponents = Array.map(
			mw.ext.LiquipediaDB.lpdb('match2opponent', {
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

---@protected
---@return string[]
function CharacterStats:getSides()
	error('CharacterStats:getSides() cannot be called directly and must be overridden.')
end

---@param games CharacterStatsGame[]
---@return CharacterStatistic[]
function CharacterStats:processGames(games)
	---@type table<string, CharacterStatistic>
	local stats = {}

	---@param isWinner boolean
	---@return 'win'|'loss'
	local function getSideKey(isWinner)
		return isWinner and 'win' or 'loss'
	end

	Array.forEach(games, function (game)
		local teamsCharacters = {
			self:getTeamCharacters(game, 1),
			self:getTeamCharacters(game, 2)
		}
		Array.forEach(game.matchOpponents, function (opponent, opponentIndex)
			local opponentName = Opponent.toName(opponent)
			local isWinner = game.winner == opponentIndex
			local side = CharacterStats:getTeamSide(game, opponentIndex)
			local characters = teamsCharacters[opponentIndex]

			Array.forEach(characters, function (character, characterIndex)
				local characterStats = self:_getCharacterStatTable(stats, character)
				if not characterStats.playedBy[opponentName] then
					characterStats.playedBy[opponentName] = {pick = 0, win = 0, loss = 0}
				end
				characterStats.total.pick = characterStats.total.pick + 1
				characterStats.playedBy[opponentName].pick = characterStats.playedBy[opponentName].pick + 1

				characterStats.total[getSideKey(isWinner)] = characterStats.total[getSideKey(isWinner)] + 1
				characterStats.side[side][getSideKey(isWinner)] = characterStats.side[side][getSideKey(isWinner)] + 1
				characterStats.playedBy[opponentName][getSideKey(isWinner)] = characterStats.playedBy[opponentName][getSideKey(isWinner)] + 1


				Array.forEach(characters, function (playedWithCharacter, playedWithCharacterIndex)
					if characterIndex == playedWithCharacterIndex then
						return
					elseif not characterStats.playedWith[playedWithCharacter] then
						characterStats.playedWith[playedWithCharacter] = {pick = 0, win = 0, loss = 0}
					end
					characterStats.playedWith[playedWithCharacter].pick = characterStats.playedWith[playedWithCharacter].pick + 1
					characterStats.playedWith[playedWithCharacter][getSideKey(isWinner)] = characterStats.playedWith[playedWithCharacter][getSideKey(isWinner)] + 1
				end)

				Array.forEach(teamsCharacters[3 - opponentIndex], function (playedAgainstCharacter)
					if not characterStats.playedVs[playedAgainstCharacter] then
						characterStats.playedVs[playedAgainstCharacter] = {pick = 0, win = 0, loss = 0}
					end
					characterStats.playedVs[playedAgainstCharacter].pick = characterStats.playedVs[playedAgainstCharacter].pick + 1
					characterStats.playedVs[playedAgainstCharacter][isWinner] = characterStats.playedVs[playedAgainstCharacter][isWinner] + 1
				end)
			end)

			Array.forEach(self:getTeamBans(game, opponentIndex), function (ban)
				local characterStats = self:_getCharacterStatTable(stats, ban)
				characterStats.bans = characterStats.bans + 1
			end)
		end)
	end)

	return Array.sortBy(Array.extractValues(stats), Operator.property('total.pick'))
end

---@private
---@param stats table<string, CharacterStatistic>
---@param character string
---@return CharacterStatistic
function CharacterStats:_getCharacterStatTable(stats, character)
	if not stats[character] then
		stats[character] = {
			name = character,
			side = Table.map(self:getSides(), function (key, value)
				return value, {win = 0, loss = 0}
			end),
			total = {pick = 0, win = 0, loss = 0},
			bans = 0,
			playedWith = {},
			playedVs = {},
			playedBy = {}
		}
	end
	return stats[character]
end

return CharacterStats
