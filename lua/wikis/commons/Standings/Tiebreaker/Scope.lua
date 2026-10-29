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

local StandingsOvertime = Lua.import('Module:Standings/Overtime')

local TiebreakerScope = {}

---Comparing different opponents can take team template lookups, and every round of the standings compares the
---same match opponents again, so the comparisons are cached.
---@param matchOpponent standardOpponent
---@param opponent standardOpponent
---@return boolean
local isSameOpponent = FnUtil.memoize2(function(matchOpponent, opponent)
	return Opponent.same(opponent, matchOpponent)
end)

---Index of the opponent in the match, 0 if it is not part of it.
---@param match MatchGroupUtilMatch
---@param opponent standardOpponent
---@return integer
function TiebreakerScope.opponentIndex(match, opponent)
	for index, matchOpponent in ipairs(match.opponents) do
		if isSameOpponent(matchOpponent, opponent) then
			return index
		end
	end
	return 0
end

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
---With overtime, results of overtime matches are tallied apart, so `match` only holds regulation results.
---@param opponent standardOpponent
---@param matches MatchGroupUtilMatch[]
---@param matchPoints table<string, number>?
---@param overtime boolean?
---@return {points: number?, match: {w: integer, d: integer, l: integer}, overtime: {w: integer, l: integer}?}
function TiebreakerScope.tally(opponent, matches, matchPoints, overtime)
	local points
	local matchRecord = {w = 0, d = 0, l = 0}
	local overtimeRecord = overtime and {w = 0, l = 0} or nil
	Array.forEach(matches, function(match)
		local pointsOfMatch = (matchPoints or {})[match.matchId]
		if pointsOfMatch then
			points = (points or 0) + pointsOfMatch
		end
		if not match.finished then
			return
		end
		-- The opponent is always part of its own matches
		local matchOpponent = match.opponents[TiebreakerScope.opponentIndex(match, opponent)]
		local result = TiebreakerScope.matchResult(match, matchOpponent)
		if overtimeRecord and result ~= 'd' and StandingsOvertime.isOvertimeMatch(match) then
			overtimeRecord[result] = overtimeRecord[result] + 1
			return
		end
		matchRecord[result] = matchRecord[result] + 1
	end)
	return {points = points, match = matchRecord, overtime = overtimeRecord}
end

---Restricts the opponents to the matches played among the tied opponents only,
---which is the scope of the head-to-head legacy (h2hlegacy) and mini-league (ml) tiebreakers.
---Returns new opponents (in the same order) and never mutates the input, as tiebreakers memoize on the
---identity of the opponent table.
---@param tiedOpponents TiebreakerOpponent[]
---@return TiebreakerOpponent[]
function TiebreakerScope.restrictTo(tiedOpponents)
	-- A match is in the matches of each of its opponents, so its opponents are looked up more than once
	---@type table<standardOpponent, boolean>
	local isTiedByMatchOpponent = {}

	---@param matchOpponent standardOpponent
	---@return boolean
	local function isTied(matchOpponent)
		if isTiedByMatchOpponent[matchOpponent] ~= nil then
			return isTiedByMatchOpponent[matchOpponent]
		end
		local tied = false
		for _, tiedOpponent in ipairs(tiedOpponents) do
			if isSameOpponent(matchOpponent, tiedOpponent.opponent) then
				tied = true
				break
			end
		end
		isTiedByMatchOpponent[matchOpponent] = tied
		return tied
	end

	---@param match MatchGroupUtilMatch
	---@return boolean
	local function isAmongTied(match)
		for _, matchOpponent in ipairs(match.opponents) do
			if not isTied(matchOpponent) then
				return false
			end
		end
		return true
	end

	return Array.map(tiedOpponents, function(tiedOpponent)
		local matches = Array.filter(tiedOpponent.matches, isAmongTied)

		local scoreboard = TiebreakerScope.tally(
			tiedOpponent.opponent, matches, tiedOpponent.matchPoints, tiedOpponent.overtime ~= nil
		)

		return {
			opponent = tiedOpponent.opponent,
			points = scoreboard.points or 0,
			matches = matches,
			matchPoints = tiedOpponent.matchPoints,
			match = scoreboard.match,
			overtime = scoreboard.overtime,
			extradata = tiedOpponent.extradata,
		}
	end)
end

return TiebreakerScope
