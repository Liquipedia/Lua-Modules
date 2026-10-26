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
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')

local TiebreakerRoundUtil = {}

---@param opponent TiebreakerOpponent
---@return {rounds: integer, w: integer, l: integer, walkoverMaps: {w: integer, l: integer},
---walkoverMatches: {w: integer, l: integer}, walkoverMatchMaps: {w: integer, l: integer}}
local getPlayedRounds = FnUtil.memoize(function (opponent)
	local rounds = 0
	local roundWins = 0
	local walkoverMaps = {w = 0, l = 0}
	local walkoverMatches = {w = 0, l = 0}
	local walkoverMatchMaps = {w = 0, l = 0}
	Array.forEach(opponent.matches, function (match)
		local opponentIndex = Array.indexOf(match.opponents, FnUtil.curry(Opponent.same, opponent.opponent))

		local matchWalkover = match.finished
			and TiebreakerGameUtil.getWalkoverResult(match.opponents[opponentIndex].status)
		if matchWalkover then
			walkoverMatches[matchWalkover] = walkoverMatches[matchWalkover] + 1
			local maps = math.floor((match.bestof or 0) / 2) + 1
			walkoverMatchMaps[matchWalkover] = walkoverMatchMaps[matchWalkover] + maps
		end

		local playedGames = Array.filter(match.games, function (game)
			return Logic.isNotEmpty(game.winner) and game.status ~= 'notplayed'
		end)
		Array.forEach(playedGames, function (game)
			local gameOpponents = game.opponents or {}
			-- The walkover of the match already covers its maps
			local mapWalkover = TiebreakerGameUtil.getWalkoverResult((gameOpponents[opponentIndex] or {}).status)
			if mapWalkover and not matchWalkover then
				walkoverMaps[mapWalkover] = walkoverMaps[mapWalkover] + 1
			end
			if Array.any(gameOpponents, function (gameOpponent)
				return Logic.isNotEmpty(gameOpponent.status) and gameOpponent.status ~= 'S'
			end) then
				return
			end
			local scores = game.scores
			rounds = rounds + MathUtil.sum(scores)
			roundWins = Operator.nilSafeAdd(roundWins, scores[opponentIndex]) --[[@as number]]
		end)
	end)
	local roundLosses = rounds - roundWins

	return {
		rounds = rounds, w = roundWins, l = roundLosses,
		walkoverMaps = walkoverMaps, walkoverMatches = walkoverMatches, walkoverMatchMaps = walkoverMatchMaps,
	}
end)

---Rounds of the played maps, a walkover map counts as `walkoverRounds` rounds. A walkover of the match counts as
---`walkoverGames` maps, or the maps needed to win the match when unset.
---@param opponent TiebreakerOpponent
---@param walkoverRounds number? # Defaults to 0, so walkovers do not count towards the rounds
---@param walkoverGames number?
---@return {rounds: integer, w: integer, l: integer}
function TiebreakerRoundUtil.getRounds(opponent, walkoverRounds, walkoverGames)
	local rounds = getPlayedRounds(opponent)
	local function walkoverRoundsOf(result)
		local matchMaps = walkoverGames and (rounds.walkoverMatches[result] * walkoverGames)
			or rounds.walkoverMatchMaps[result]
		return (rounds.walkoverMaps[result] + matchMaps) * (walkoverRounds or 0)
	end
	local walkoverWins = walkoverRoundsOf('w')
	local walkoverLosses = walkoverRoundsOf('l')
	return {
		rounds = rounds.rounds + walkoverWins + walkoverLosses,
		w = rounds.w + walkoverWins,
		l = rounds.l + walkoverLosses,
	}
end

return TiebreakerRoundUtil
