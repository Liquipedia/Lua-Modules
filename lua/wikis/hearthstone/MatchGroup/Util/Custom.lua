---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local Opponent = Lua.import('Module:Opponent/Custom')

local SCORE_STATUS = 'S'

local CustomMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

---@class HearthstoneMatchGroupUtilGameOpponent: GameOpponent
---@field placement number?

---@class HearthstoneMatchGroupUtilSubmatch: MatchGroupUtilSubgroup
---@field opponents HearthstoneMatchGroupUtilGameOpponent[]
---@field winner number?
---@field header string?

---@class HearthstoneMatchGroupUtilMatch: MatchGroupUtilMatch
---@field submatches HearthstoneMatchGroupUtilSubmatch[]?
---@field isTeamMatch boolean

---@param record match2
---@return HearthstoneMatchGroupUtilMatch
function CustomMatchGroupUtil.matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record) --[[@as HearthstoneMatchGroupUtilMatch]]

	-- Adjust game.opponents by looking up game.opponents.players in match.opponents
	Array.forEach(match.games, function(game)
		game.opponents = CustomMatchGroupUtil.computeGameOpponents(game, match.opponents)
	end)

	match.isTeamMatch = Array.any(match.opponents, function(opponent)
		return opponent.type == Opponent.team end
	)

	if not match.isTeamMatch then
		return match
	end

	-- Compute submatches
	match.submatches = Array.map(
		MatchGroupUtil.groupBySubgroup(match.games),
		FnUtil.curry(CustomMatchGroupUtil.constructSubmatch, match)
	)

	return match
end

---@param game MatchGroupUtilGame
---@param matchOpponents standardOpponent[]
---@return table[]
function CustomMatchGroupUtil.computeGameOpponents(game, matchOpponents)
	return Array.map(game.opponents, function (opponent, opponentIndex)
		return Table.merge(opponent, {
			players = Array.map(game.opponents[opponentIndex].players or {}, function (player, playerIndex)
				if Logic.isEmpty(player) then return nil end
				return Table.merge(matchOpponents[opponentIndex].players[playerIndex] or {}, player)
			end)
		})
	end)
end

---Constructs a submatch object whose properties are aggregated from that of its games.
---@param match HearthstoneMatchGroupUtilMatch
---@param subgroup MatchGroupUtilSubgroup
---@return HearthstoneMatchGroupUtilSubmatch
function CustomMatchGroupUtil.constructSubmatch(match, subgroup)
	local games = subgroup.games
	local firstGame = games[1]
	local opponents = Table.deepCopy(firstGame.opponents)
	local isSubmatch = string.find(firstGame.map or '', '^[sS]ubmatch %d+$')
	if isSubmatch then
		games = {firstGame}
	end

	---@param opponent table
	---@param opponentIndex number
	local getOpponentScoreAndStatus = function(opponent, opponentIndex)
		local statuses = Array.unique(Array.map(games, function(game)
			return game.opponents[opponentIndex].status
		end))
		opponent.status = #statuses == 1 and statuses[1] ~= SCORE_STATUS and statuses[1] or SCORE_STATUS
		opponent.score = isSubmatch and firstGame.scores[opponentIndex] or Array.reduce(Array.map(games, function(game)
			return (game.winner == opponentIndex and 1 or 0)
		end), Operator.add)
	end

	Array.forEach(opponents, getOpponentScoreAndStatus)

	local allPlayed = Array.all(games, function (game) return game.winner ~= nil end)
	local winner = allPlayed and MatchGroupInputUtil.getWinner('', nil, opponents) or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.placement = MatchGroupInputUtil.placementFromWinner('', winner, opponentIndex)
	end)

	local matchExtradata = match.extradata or {}

	return Table.mergeInto({
		header = Table.extract(matchExtradata, 'subgroup' .. subgroup.subgroup .. 'header'),
		opponents = opponents,
		winner = winner,
	}, subgroup)
end

return CustomMatchGroupUtil
