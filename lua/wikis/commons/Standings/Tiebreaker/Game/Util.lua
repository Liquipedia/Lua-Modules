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
local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerGameUtil = {}

---@param opponent TiebreakerOpponent
---@return {games: integer, w: integer, d: integer, l: integer}
TiebreakerGameUtil.getGames = FnUtil.memoize(function(opponent)
	local games = 0
	local gameWins = 0
	local gameDraws = 0
	Array.forEach(opponent.matches, function(match)
		local playedGames = Array.filter(match.games, function(game)
			return Logic.isNotEmpty(game.winner) and game.status ~= 'notplayed'
		end)

		if #playedGames > 0 then -- If individual game data exists, use it
			games = games + #playedGames
			gameWins = gameWins + #Array.filter(playedGames, function(game)
				if game.resultType == 'draw' then
					gameDraws = gameDraws + 1
					return false
				end
				return Opponent.same(opponent.opponent, match.opponents[game.winner])
			end)
		elseif match.finished then -- Fallback: infer from series score when individual games are not recorded
			local opponentInMatch = Array.find(match.opponents, function(opp)
				return Opponent.same(opponent.opponent, opp)
			end)

			if opponentInMatch then
				local myScore = tonumber(opponentInMatch.score) or 0

				-- Handle draws at match level
				if match.winner == 0 then
					-- Match was a draw - don't count any games (or could count as draws if needed)
					-- This is ambiguous without individual game data
					gameDraws = gameDraws + 1
				else
					-- Find opponent's score to calculate game losses
					local otherOpponent = Array.find(match.opponents, function(opp)
						return not Opponent.same(opponent.opponent, opp)
					end)

					if otherOpponent then
						local theirScore = tonumber(otherOpponent.score) or 0
						-- Series score represents game wins/losses
						gameWins = gameWins + myScore
						games = games + myScore + theirScore
					end
				end
			end
		end
	end)
	local gameLosses = games - gameWins - gameDraws

	return { games = games, w = gameWins, d = gameDraws, l = gameLosses }
end)

return TiebreakerGameUtil
