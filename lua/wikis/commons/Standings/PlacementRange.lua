---
-- @Liquipedia
-- page=Module:Standings/PlacementRange
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

---The best and worst final placement of the opponents of a round, calculated per format
local StandingsPlacementRange = {}

---@alias StandingsFormat StandingsSwissFormat|StandingsRoundRobinFormat|StandingsClassicSwissFormat

---@alias StandingsPlacementRangeValue {[1]: integer, [2]: integer}

---@alias StandingsPlacementRangeEntry {match: {w: integer, d: integer, l: integer}, overtime: table?,
---extradata: table, slotindex: integer, placerange: StandingsPlacementRangeValue?}

---@class StandingsPlacementRangeContext
---@field tiebreakerIds string[]
---@field points table<string, number>? The points per result, see StandingsParseWiki.parsePoints

---@class StandingsPlacementRangeCalculator
---@field firstMatchAdjustmentRound integer?
---@field rangesFor fun(self, entriesInRound: StandingsPlacementRangeEntry[]): StandingsPlacementRangeValue[]?

---@type table<string, string>
local TYPE_TO_CLASS = {
	swiss = 'Swiss',
	roundrobin = 'RemainingMatches',
	classicswiss = 'RemainingMatches',
}

---@param opponents StandingTableOpponentData[]
---@return integer?
local function firstMatchAdjustmentRound(opponents)
	---@type integer[]
	local rounds = Array.flatMap(opponents, function(opponentData)
		local adjustments = opponentData.adjustments or {}
		return Array.filter(Array.extractKeys(adjustments), function(round)
			return adjustments[round].match ~= nil
		end)
	end)
	return Array.min(rounds)
end

---Nil if the opponents do not fit the format.
---@param format StandingsFormat
---@param opponents StandingTableOpponentData[]
---@param context StandingsPlacementRangeContext?
---@return StandingsPlacementRangeCalculator?
function StandingsPlacementRange.calculator(format, opponents, context)
	local CalculatorClass = Lua.import('Module:Standings/PlacementRange/' .. TYPE_TO_CLASS[format.type])
	local calculator = CalculatorClass.new(format, opponents, context)
	if calculator then
		calculator.firstMatchAdjustmentRound = firstMatchAdjustmentRound(opponents)
	end
	return calculator
end

---Sets `placerange` on the entries of a round, unless the calculator has no ranges or a slot is out of range.
---@param calculator StandingsPlacementRangeCalculator
---@param entriesInRound StandingsPlacementRangeEntry[]
---@param roundNumber integer
function StandingsPlacementRange.setRanges(calculator, entriesInRound, roundNumber)
	-- No format follows disqualifications or adjusted match records
	local isAdjusted = roundNumber >= (calculator.firstMatchAdjustmentRound or math.huge)
	local ranges = not isAdjusted
		and not Array.any(entriesInRound, function(entry) return entry.extradata.disqualified end)
		and calculator:rangesFor(entriesInRound)
	if not ranges then
		return
	end
	-- Tiebreakers that do not rank like the format can contradict the ranges
	for index, entry in ipairs(entriesInRound) do
		if entry.slotindex < ranges[index][1] or entry.slotindex > ranges[index][2] then
			return
		end
	end
	Array.forEach(entriesInRound, function(entry, index)
		entry.placerange = {ranges[index][1], ranges[index][2]}
	end)
end

return StandingsPlacementRange
