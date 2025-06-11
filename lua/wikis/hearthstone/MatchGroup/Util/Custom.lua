---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local SCORE_STATUS = 'S'

local CustomMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

---@class HearthstoneMatchGroupUtilGameOpponent: GameOpponent
---@field placement number?

---@class HearthstoneMatchGroupUtilSubmatch
---@field games MatchGroupUtilGame[]
---@field opponents HearthstoneMatchGroupUtilGameOpponent[]
---@field subgroup number
---@field winner number?
---@field header string?

---@class HearthstoneMatchGroupUtilMatch: MatchGroupUtilMatch
---@field submatches HearthstoneMatchGroupUtilSubmatch[]?
---@field isTeamMatch boolean

---@param record table
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
		CustomMatchGroupUtil.groupBySubmatch(match.games),
		function(games) return CustomMatchGroupUtil.constructSubmatch(games) end
	)

	local extradata = match.extradata
	---@cast extradata table
	Array.forEach(match.submatches, function (submatch)
		submatch.header = Table.extract(extradata, 'subgroup' .. submatch.subgroup .. 'header')
	end)

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

---Group games on the subgroup field to form submatches
---@param matchGames MatchGroupUtilGame[]
---@return MatchGroupUtilGame[][]
function CustomMatchGroupUtil.groupBySubmatch(matchGames)
	-- Group games on adjacent subgroups
	local previousSubgroup = nil
	local currentGames = nil
	local submatchGames = {}
	Array.forEach(matchGames, function (game)
		if previousSubgroup == nil or previousSubgroup ~= game.subgroup then
			currentGames = {}
			table.insert(submatchGames, currentGames)
			previousSubgroup = game.subgroup
		end
		---@cast currentGames -nil
		table.insert(currentGames, game)
	end)
	return submatchGames
end

---Constructs a submatch object whose properties are aggregated from that of its games.
---@param games MatchGroupUtilGame[]
---@return HearthstoneMatchGroupUtilSubmatch
function CustomMatchGroupUtil.constructSubmatch(games)
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

	return {
		games = games,
		opponents = opponents,
		subgroup = firstGame.subgroup,
		winner = winner,
	}
end

return CustomMatchGroupUtil
