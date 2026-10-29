---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/MatchCounter
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FnUtil = Lua.import('Module:FnUtil')
local Table = Lua.import('Module:Table')

local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

---Counts over the matches of an opponent, e.g. the games or rounds it won and lost.
local TiebreakerMatchCounter = {}

---Every round of an opponent has the matches of the rounds before it, so the counts over its matches continue the
---counts of the round before, as long as the matches of the round before are the first matches of this round.
---@param opponent TiebreakerOpponent
---@return TiebreakerOpponent? previousRound # The round before, if its counts can be continued
---@return integer firstMatchIndex # Index of the first match that is not counted in the round before
function TiebreakerMatchCounter.continuedRound(opponent)
	local previousRound = opponent.previousRound
	if not previousRound or #previousRound.matches > #opponent.matches then
		return nil, 1
	end
	for index, match in ipairs(previousRound.matches) do
		if opponent.matches[index] ~= match then
			return nil, 1
		end
	end
	return previousRound, #previousRound.matches + 1
end

---Creates a count over the matches of an opponent, memoized per opponent (and round).
---The returned counts are shared, so they must not be changed.
---@param zero table # The counts without any matches
---@param addMatch fun(counts: table, match: MatchGroupUtilMatch, opponentIndex: integer) # Adds a match to the counts
---@return fun(opponent: TiebreakerOpponent): table
function TiebreakerMatchCounter.create(zero, addMatch)
	local count
	count = FnUtil.memoize(function(opponent)
		local previousRound, firstMatchIndex = TiebreakerMatchCounter.continuedRound(opponent)
		local counts = Table.deepCopy(previousRound and count(previousRound) or zero)
		for index = firstMatchIndex, #opponent.matches do
			local match = opponent.matches[index]
			addMatch(counts, match, TiebreakerScope.opponentIndex(match, opponent.opponent))
		end
		return counts
	end)
	return count
end

return TiebreakerMatchCounter
