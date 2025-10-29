---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerGameUtil = {}

---@param opponent TiebreakerOpponent
---@return {games: integer, w: integer, d: integer, l: integer, walkover: {w: integer, l: integer}?}
TiebreakerGameUtil.getGames = FnUtil.memoize(function (opponent)
	local games = 0
	local gameWins = 0
	local gameDraws = 0
	local walkoverWins = 0
	local walkoverLosses = 0
	Array.forEach(opponent.matches, function (match)
		local playedGames = Array.filter(match.games, function (game)
			return Logic.isNotEmpty(game.winner) and game.status ~= 'notplayed'
		end)
		if Logic.isNotEmpty(playedGames) then
			--Use game data by default, if it is available
			games = games + #playedGames
			gameWins = gameWins + #Array.filter(playedGames, function (game)
				if game.resultType == 'draw' then
					gameDraws = gameDraws + 1
					return false
				end
				return Opponent.same(opponent.opponent, match.opponents[game.winner])
			end)
		else
			local opponentIndex = Array.indexOf(match.opponents, FnUtil.curry(Opponent.same, opponent.opponent))
			--Fall back to using match score if game data is unavailable
			if Array.any(match.opponents, function (matchOpponent)
				return matchOpponent.status ~= 'S'
			end) then
				if match.winner == opponentIndex then
					walkoverWins = walkoverWins + 1
				else
					walkoverLosses = walkoverLosses + 1
				end
				return
			end
			games = games + Array.reduce(match.opponents, Operator.property('score'))
			gameWins = gameWins + match.opponents[opponentIndex].score
		end
	end)
	local gameLosses = games - gameWins - gameDraws

	return {
		games = games, w = gameWins, d = gameDraws, l = gameLosses,
		walkover = Logic.nilIfEmpty{
			w = walkoverWins > 0 and walkoverWins or nil,
			l = walkoverLosses > 0 and walkoverLosses or nil,
		}
	}
end)

return TiebreakerGameUtil
