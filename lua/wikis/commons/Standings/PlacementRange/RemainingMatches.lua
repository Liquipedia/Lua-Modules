---
-- @Liquipedia
-- page=Module:Standings/PlacementRange/RemainingMatches
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local TiebreakerFactory = Lua.import('Module:Standings/Tiebreaker/Factory')
local TiebreakerMatchUtil = Lua.import('Module:Standings/Tiebreaker/Match/Util')

---@class StandingsRoundRobinFormat
---@field type 'roundrobin'
---@field cycles integer

---@class StandingsClassicSwissFormat
---@field type 'classicswiss'
---@field rounds integer

---The least and most a match adds to the value of a supported first tiebreaker
---@type table<string, fun(points: table<string, number>?, winWeight: integer): number[]?>
local GAINS = {
	['full.points'] = function(points)
		local values = points and Array.extractValues(points)
		return values and {Array.min(values), Array.max(values)}
	end,
	['full.matchwins'] = function() return {0, 1} end,
	['full.matchlosses'] = function() return {-1, 0} end,
	['full.matchdiff'] = function() return {-1, 1} end,
	['full.matchdraws'] = function() return {0, 1} end,
	['full.matchscore'] = function(_, winWeight) return {-1, winWeight} end,
}

---Round robin and classic swiss: each match left adds the least or the most a match can, whoever the opponent
---@class StandingsRemainingMatchesPlacementRange: StandingsPlacementRangeCalculator
---@field matchesPerOpponent integer
---@field tiebreaker StandingsTiebreaker
---@field minGain number
---@field maxGain number
local StandingsRemainingMatchesPlacementRange = Class.new(function(self, matchesPerOpponent, tiebreakerId, gains)
	self.matchesPerOpponent = matchesPerOpponent
	self.tiebreaker = TiebreakerFactory.tiebreakerFromId(tiebreakerId)
	self.minGain, self.maxGain = gains[1], gains[2]
end)

---Nil if the first tiebreaker after disqualified is not supported.
---@param format StandingsRoundRobinFormat|StandingsClassicSwissFormat
---@param opponents StandingTableOpponentData[]
---@param context StandingsPlacementRangeContext
---@return StandingsRemainingMatchesPlacementRange?
function StandingsRemainingMatchesPlacementRange.new(format, opponents, context)
	local tiebreakerId = Array.find(context.tiebreakerIds, function(id) return id ~= 'full.disqualified' end)
	local getGains = GAINS[tiebreakerId]
	local matchesPerOpponent = format.type == 'roundrobin' and format.cycles * (#opponents - 1) or format.rounds
	local gains = getGains and getGains(context.points, matchesPerOpponent + 1)
	return gains and StandingsRemainingMatchesPlacementRange(matchesPerOpponent, tiebreakerId, gains)
end

---Number of values in the ascending list above the threshold, or at least the threshold with `orEqual`.
---@param sortedValues number[]
---@param threshold number
---@param orEqual boolean?
---@return integer
local function countAbove(sortedValues, threshold, orEqual)
	local first, last = 1, #sortedValues + 1
	while first < last do
		local middle = math.floor((first + last) / 2)
		local value = sortedValues[middle]
		if value > threshold or (orEqual and value == threshold) then
			last = middle
		else
			first = middle + 1
		end
	end
	return #sortedValues - first + 1
end

---@param entriesInRound TiebreakerOpponent[]
---@return StandingsPlacementRangeValue[]?
function StandingsRemainingMatchesPlacementRange:rangesFor(entriesInRound)
	local lows, highs = {}, {}
	for index, entry in ipairs(entriesInRound) do
		local matches = TiebreakerMatchUtil.getMatches(entry)
		local remaining = self.matchesPerOpponent - matches.w - matches.d - matches.l
		if remaining < 0 then
			return nil
		end
		local value = self.tiebreaker:valueOf(entriesInRound, entry)
		if type(value) == 'table' then
			-- The match score {wins, -losses} as one number, a win outweighs all losses
			value = value[1] * (self.matchesPerOpponent + 1) + value[2]
		end
		-- Matches can be left unplayed, so the current value stays within the bounds
		lows[index] = value + math.min(0, self.minGain * remaining)
		highs[index] = value + math.max(0, self.maxGain * remaining)
	end
	local sortedLows, sortedHighs = Array.copy(lows), Array.copy(highs)
	table.sort(sortedLows)
	table.sort(sortedHighs)
	-- Ties go against the opponent for the worst placement, which counts the opponent itself
	return Array.map(entriesInRound, function(_, index)
		return {1 + countAbove(sortedLows, highs[index]), countAbove(sortedHighs, lows[index], true)}
	end)
end

return StandingsRemainingMatchesPlacementRange
