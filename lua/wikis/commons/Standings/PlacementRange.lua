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

---@alias StandingsFormat StandingsSwissFormat

---@alias StandingsPlacementRangeValue {[1]: integer, [2]: integer}

---@alias StandingsPlacementRangeEntry {match: {w: integer, d: integer, l: integer}, overtime: table?,
---extradata: table, slotindex: integer, placerange: StandingsPlacementRangeValue?}

---@class StandingsPlacementRangeCalculator
---@field rangesFor fun(self, entriesInRound: StandingsPlacementRangeEntry[],
---roundNumber: integer): StandingsPlacementRangeValue[]?

---@type table<string, string>
local TYPE_TO_CLASS = {
	swiss = 'Swiss',
}

---Nil if the opponents do not fit the format.
---@param format StandingsFormat
---@param opponents StandingTableOpponentData[]
---@return StandingsPlacementRangeCalculator?
function StandingsPlacementRange.calculator(format, opponents)
	local CalculatorClass = Lua.import('Module:Standings/PlacementRange/' .. TYPE_TO_CLASS[format.type])
	return CalculatorClass.new(format, opponents)
end

---Sets `placerange` on the entries of a round, unless the calculator has no ranges or a slot is out of range.
---@param calculator StandingsPlacementRangeCalculator
---@param entriesInRound StandingsPlacementRangeEntry[]
---@param roundNumber integer
function StandingsPlacementRange.setRanges(calculator, entriesInRound, roundNumber)
	local ranges = calculator:rangesFor(entriesInRound, roundNumber)
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
