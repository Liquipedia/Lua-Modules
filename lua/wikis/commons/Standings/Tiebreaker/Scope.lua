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

---Tallies the points and the match record of an opponent over the given matches.
---Unfinished matches only count towards the points, not the match record.
---The points are nil if none of the matches gave the opponent points.
---@param opponent standardOpponent
---@param matches MatchGroupUtilMatch[]
---@param matchPoints table<string, number>?
---@return {points: number?, match: {w: integer, d: integer, l: integer}}
function TiebreakerScope.tally(opponent, matches, matchPoints)
	local points
	local matchRecord = {w = 0, d = 0, l = 0}
	Array.forEach(matches, function(match)
		local pointsOfMatch = (matchPoints or {})[match.matchId]
		if pointsOfMatch then
			points = (points or 0) + pointsOfMatch
		end
		if not match.finished then
			return
		end
		-- The opponent is always part of its own matches
		local matchOpponent = Array.find(match.opponents, FnUtil.curry(Opponent.same, opponent))
		---@cast matchOpponent -nil
		local result = TiebreakerScope.matchResult(match, matchOpponent)
		matchRecord[result] = matchRecord[result] + 1
	end)
	return {points = points, match = matchRecord}
end

---Restricts the opponents to the matches played among the tied opponents only,
---which is the scope of the head-to-head (h2hcs, h2hlegacy) and mini-league (ml) tiebreakers.
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

		local scoreboard = TiebreakerScope.tally(tiedOpponent.opponent, matches, tiedOpponent.matchPoints)

		return {
			opponent = tiedOpponent.opponent,
			points = scoreboard.points or 0,
			matches = matches,
			matchPoints = tiedOpponent.matchPoints,
			match = scoreboard.match,
			extradata = tiedOpponent.extradata,
		}
	end)
end

return TiebreakerScope
