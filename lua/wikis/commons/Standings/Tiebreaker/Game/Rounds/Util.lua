---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

local TiebreakerRoundUtil = {}

---Whether none of the opponents of a game has a status other than a score.
---@param gameOpponents table[]
---@return boolean
local function isScored(gameOpponents)
	for _, gameOpponent in ipairs(gameOpponents) do
		if Logic.isNotEmpty(gameOpponent.status) and gameOpponent.status ~= 'S' then
			return false
		end
	end
	return true
end

local getPlayedRounds
---@param opponent TiebreakerOpponent
---@return {rounds: integer, w: integer, l: integer, walkoverMaps: {w: integer, l: integer},
---walkoverMatches: {w: integer, l: integer}, walkoverMatchMaps: {w: integer, l: integer}}
getPlayedRounds = FnUtil.memoize(function (opponent)
	local previousRound, firstMatchIndex = TiebreakerGameUtil.continuedRound(opponent)
	local previous = previousRound and getPlayedRounds(previousRound)
	local rounds = previous and previous.rounds or 0
	local roundWins = previous and previous.w or 0
	local walkoverMaps = previous and Table.copy(previous.walkoverMaps) or {w = 0, l = 0}
	local walkoverMatches = previous and Table.copy(previous.walkoverMatches) or {w = 0, l = 0}
	local walkoverMatchMaps = previous and Table.copy(previous.walkoverMatchMaps) or {w = 0, l = 0}
	for index = firstMatchIndex, #opponent.matches do
		local match = opponent.matches[index]
		local opponentIndex = TiebreakerScope.opponentIndex(match, opponent.opponent)

		local matchWalkover = match.finished
			and TiebreakerGameUtil.getWalkoverResult(match.opponents[opponentIndex].status)
		if matchWalkover then
			walkoverMatches[matchWalkover] = walkoverMatches[matchWalkover] + 1
			local maps = math.floor((match.bestof or 0) / 2) + 1
			walkoverMatchMaps[matchWalkover] = walkoverMatchMaps[matchWalkover] + maps
		end

		for _, game in ipairs(match.games) do
			if Logic.isNotEmpty(game.winner) and game.status ~= 'notplayed' then
				local gameOpponents = game.opponents or {}
				-- The walkover of the match already covers its maps
				local mapWalkover = TiebreakerGameUtil.getWalkoverResult((gameOpponents[opponentIndex] or {}).status)
				if mapWalkover and not matchWalkover then
					walkoverMaps[mapWalkover] = walkoverMaps[mapWalkover] + 1
				end
				if isScored(gameOpponents) then
					local scores = game.scores
					rounds = rounds + MathUtil.sum(scores)
					roundWins = Operator.nilSafeAdd(roundWins, scores[opponentIndex]) --[[@as number]]
				end
			end
		end
	end
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
