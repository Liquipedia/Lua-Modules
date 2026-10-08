---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Scope
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Opponent = Lua.import('Module:Opponent/Custom')

local TiebreakerScope = {}

---Result of a finished match from the point of view of one of its opponents.
---@param match MatchGroupUtilMatch
---@param matchOpponent standardOpponent
---@return 'w'|'d'|'l'
function TiebreakerScope.matchResult(match, matchOpponent)
	return match.winner == 0 and 'd' or matchOpponent.placement == 1 and 'w' or 'l'
end

---Restricts the opponents to the matches played among the tied opponents only,
---which is the scope of the head-to-head (h2h) and mini-league (ml) tiebreakers.
---Returns new opponents (in the same order) and never mutates the input, as tiebreakers memoize on the
---identity of the opponent table.
---@param tiedOpponents TiebreakerOpponent[]
---@return TiebreakerOpponent[]
function TiebreakerScope.restrictTo(tiedOpponents)
	local isTied = function(matchOpponent)
		return Array.any(tiedOpponents, function(tiedOpponent)
			return Opponent.same(tiedOpponent.opponent, matchOpponent)
		end)
	end

	return Array.map(tiedOpponents, function(tiedOpponent)
		local matches = Array.filter(tiedOpponent.matches, function(match)
			return Array.all(match.opponents, isTied)
		end)

		local matchRecord = {w = 0, d = 0, l = 0}
		local points = 0
		Array.forEach(matches, function(match)
			points = points + ((tiedOpponent.matchPoints or {})[match.matchId] or 0)
			if not match.finished then
				return
			end
			-- The opponent is always part of its own matches
			local matchOpponent = Array.find(match.opponents, FnUtil.curry(Opponent.same, tiedOpponent.opponent))
			---@cast matchOpponent -nil
			local result = TiebreakerScope.matchResult(match, matchOpponent)
			matchRecord[result] = matchRecord[result] + 1
		end)

		return {
			opponent = tiedOpponent.opponent,
			points = points,
			matches = matches,
			matchPoints = tiedOpponent.matchPoints,
			match = matchRecord,
			extradata = tiedOpponent.extradata,
		}
	end)
end

return TiebreakerScope
