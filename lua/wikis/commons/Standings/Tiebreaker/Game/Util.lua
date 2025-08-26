---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerGameUtil = {}

---@param opponent TiebreakerOpponent
---@return {games: integer, w: integer, d: integer, l: integer}
function TiebreakerGameUtil.getGames(opponent)
	local games = 0
	local gameWins = 0
	local gameDraws = 0
	Array.forEach(opponent.matches, function (match)
		local playedGames = Array.filter(match.games, function (game)
			return Logic.isNotEmpty(game.winner) and game.status ~= 'notplayed'
		end)
		games = games + #playedGames
		gameWins = gameWins + #Array.filter(playedGames, function (game)
			if game.winner == 0 then
				gameDraws = gameDraws + 1
				return false
			end
			return Opponent.same(opponent.opponent, match.opponents[game.winner])
		end)
	end)
	local gameLosses = games - gameWins - gameDraws

	return {games = games, w = gameWins, d = gameDraws, l = gameLosses}
end

return TiebreakerGameUtil
