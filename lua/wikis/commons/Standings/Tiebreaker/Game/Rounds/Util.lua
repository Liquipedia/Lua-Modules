---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Rounds/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerMatchCounter = Lua.import('Module:Standings/Tiebreaker/MatchCounter')

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

---@type fun(opponent: TiebreakerOpponent): {rounds: integer, w: integer, walkoverMaps: {w: integer, l: integer},
---walkoverMatches: {w: integer, l: integer}, walkoverMatchMaps: {w: integer, l: integer}}
local countPlayedRounds = TiebreakerMatchCounter.create(
	{
		rounds = 0, w = 0,
		walkoverMaps = {w = 0, l = 0}, walkoverMatches = {w = 0, l = 0}, walkoverMatchMaps = {w = 0, l = 0},
	},
	function (counts, match, opponentIndex)
		local matchWalkover = match.finished
			and TiebreakerGameUtil.getWalkoverResult(match.opponents[opponentIndex].status)
		if matchWalkover then
			counts.walkoverMatches[matchWalkover] = counts.walkoverMatches[matchWalkover] + 1
			local maps = math.floor((match.bestof or 0) / 2) + 1
			counts.walkoverMatchMaps[matchWalkover] = counts.walkoverMatchMaps[matchWalkover] + maps
		end

		for _, game in ipairs(match.games) do
			if Logic.isNotEmpty(game.winner) and game.status ~= 'notplayed' then
				local gameOpponents = game.opponents or {}
				-- The walkover of the match already covers its maps
				local mapWalkover = TiebreakerGameUtil.getWalkoverResult((gameOpponents[opponentIndex] or {}).status)
				if mapWalkover and not matchWalkover then
					counts.walkoverMaps[mapWalkover] = counts.walkoverMaps[mapWalkover] + 1
				end
				if isScored(gameOpponents) then
					local scores = game.scores
					counts.rounds = counts.rounds + MathUtil.sum(scores)
					counts.w = Operator.nilSafeAdd(counts.w, scores[opponentIndex]) --[[@as number]]
				end
			end
		end
	end
)

---Rounds of the played maps, a walkover map counts as `walkoverRounds` rounds. A walkover of the match counts as
---`walkoverGames` maps, or the maps needed to win the match when unset.
---@param opponent TiebreakerOpponent
---@param walkoverRounds number? # Defaults to 0, so walkovers do not count towards the rounds
---@param walkoverGames number?
---@return {rounds: integer, w: integer, l: integer}
function TiebreakerRoundUtil.getRounds(opponent, walkoverRounds, walkoverGames)
	local rounds = countPlayedRounds(opponent)
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
		l = rounds.rounds - rounds.w + walkoverLosses,
	}
end

return TiebreakerRoundUtil
