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
		return Array.map(slots, function(slot) return {slotindex = slot, extradata = {}} end)
	end

	local GSL = {type = 'swiss', winsToAdvance = 2, lossesToEliminate = 2}

	---@return table[]
	local function opponentsData()
		return Array.map(Array.range(1, 4), function() return {} end)
	end

	it('picks the calculator of the format type', function()
		assert.is_not_nil(StandingsPlacementRange.calculator(GSL, opponentsData()))
		assert.is_nil(StandingsPlacementRange.calculator(GSL, Array.sub(opponentsData(), 1, 3)))
	end)

	it('finds the first round with an adjusted match record', function()
		local opponents = opponentsData()
		opponents[2].adjustments = {[1] = {points = 2}, [3] = {match = {w = 1}}}
		opponents[3].adjustments = {[2] = {match = {l = 1}}}
		assert.are_equal(2, StandingsPlacementRange.calculator(GSL, opponents).firstMatchAdjustmentRound)
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

	it('sets no ranges with a disqualified opponent', function()
		local entries = makeEntries{1, 2}
		entries[2].extradata.disqualified = true
		StandingsPlacementRange.setRanges(stubCalculator{{1, 1}, {2, 2}}, entries, 1)
		assert.is_nil(entries[1].placerange)
	end)

	it('sets no ranges from the round a match record is adjusted', function()
		local calculator = stubCalculator{{1, 1}, {2, 2}}
		calculator.firstMatchAdjustmentRound = 2
		local beforeAdjustment, fromAdjustment = makeEntries{1, 2}, makeEntries{1, 2}
		StandingsPlacementRange.setRanges(calculator, beforeAdjustment, 1)
		StandingsPlacementRange.setRanges(calculator, fromAdjustment, 2)
		assert.are_same({1, 1}, beforeAdjustment[1].placerange)
		assert.is_nil(fromAdjustment[1].placerange)
	end)

	it('sets no ranges when a slot is outside its range', function()
		local entries = makeEntries{2, 1}
		StandingsPlacementRange.setRanges(stubCalculator{{1, 1}, {2, 2}}, entries, 1)
		assert.is_nil(entries[1].placerange)
		assert.is_nil(entries[2].placerange)
	end)
end)
