---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerRoundUtil = {}

---@param opponent TiebreakerOpponent
---@return {rounds: integer, w: integer, l: integer}
TiebreakerRoundUtil.getGames = FnUtil.memoize(function (opponent)
	local rounds = 0
	local roundWins = 0
	Array.forEach(opponent.matches, function (match)
		local opponentIndex = Array.indexOf(match.opponents, FnUtil.curry(Opponent.same, opponent.opponent))
		local playedGames = Array.filter(match.games, function (game)
			return Logic.isNotEmpty(game.winner) and game.status ~= 'notplayed'
		end)
		if Logic.isEmpty(playedGames) then
			return
		end
		rounds = rounds + Array.reduce(
			Array.map(playedGames, Operator.property('scores')),
			function (aggregate, gameScores)
				return aggregate + Array.reduce(gameScores, Operator.add, 0)
			end,
			0
		)
		roundWins = roundWins + Array.reduce(
			Array.map(playedGames, function (game)
				return game.scores[opponentIndex]
			end),
			Operator.add,
			0
		)
	end)
	local roundLosses = rounds - roundWins

	return {rounds = rounds, w = roundWins, l = roundLosses}
end)

return TiebreakerRoundUtil
