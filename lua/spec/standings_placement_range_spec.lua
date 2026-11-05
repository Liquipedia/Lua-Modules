--- Triple Comment to Enable our LLS Plugin
describe('Standings Placement Range', function()
	local Array = require('Module:Array')
	local StandingsPlacementRange = require('Module:Standings/PlacementRange')

	---@param ranges table[]?
	---@return StandingsPlacementRangeCalculator
	local function stubCalculator(ranges)
		return {rangesFor = function() return ranges end}
	end

	---@param slots integer[]
	---@return table[]
	local function makeEntries(slots)
		return Array.map(slots, function(slot) return {slotindex = slot} end)
	end

	it('picks the calculator of the format type', function()
		local format = {type = 'swiss', winsToAdvance = 2, lossesToEliminate = 2}
		local opponents = Array.map(Array.range(1, 4), function() return {} end)
		assert.is_not_nil(StandingsPlacementRange.calculator(format, opponents))
		assert.is_nil(StandingsPlacementRange.calculator(format, Array.sub(opponents, 1, 3)))
	end)

	it('sets the ranges of the calculator', function()
		local entries = makeEntries{1, 2}
		StandingsPlacementRange.setRanges(stubCalculator{{1, 1}, {2, 2}}, entries, 1)
		assert.are_same({1, 1}, entries[1].placerange)
		assert.are_same({2, 2}, entries[2].placerange)
	end)

	it('sets no ranges without ranges of the calculator', function()
		local entries = makeEntries{1, 2}
		StandingsPlacementRange.setRanges(stubCalculator(nil), entries, 1)
		assert.is_nil(entries[1].placerange)
		assert.is_nil(entries[2].placerange)
	end)

	it('sets no ranges when a slot is outside its range', function()
		local entries = makeEntries{2, 1}
		StandingsPlacementRange.setRanges(stubCalculator{{1, 1}, {2, 2}}, entries, 1)
		assert.is_nil(entries[1].placerange)
		assert.is_nil(entries[2].placerange)
	end)
end)
