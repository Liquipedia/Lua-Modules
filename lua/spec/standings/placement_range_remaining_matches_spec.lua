--- Triple Comment to Enable our LLS Plugin
describe('Standings Remaining Matches Placement Range', function()
	local Array = require('Module:Array')
	local Operator = require('Module:Operator')
	local StandingsPlacementRange = require('Module:Standings/PlacementRange')

	local SRR = {type = 'roundrobin', cycles = 1}
	local CLASSIC_SWISS = {type = 'classicswiss', rounds = 3}
	local POINTS = {w = 3, d = 1, l = 0}
	local POINTS_CONTEXT = {tiebreakerIds = {'full.disqualified', 'full.points', 'full.manual'}, points = POINTS}

	---@param records {[1]: integer, [2]: integer, [3]: integer?}[] wins, losses and draws
	---@param points table<string, number>?
	---@return table[]
	local function makeEntries(records, points)
		points = points or POINTS
		return Array.map(records, function(record)
			local match = {w = record[1], d = record[3] or 0, l = record[2]}
			return {points = match.w * points.w + match.d * points.d + match.l * points.l, match = match, extradata = {}}
		end)
	end

	---@param format table
	---@param entries table[]
	---@param context table?
	---@return table[]?
	local function rangesOf(format, entries, context)
		local opponents = Array.map(entries, function() return {} end)
		local calculator = StandingsPlacementRange.calculator(format, opponents, context or POINTS_CONTEXT)
		return calculator and calculator:rangesFor(entries)
	end

	it('bounds the placements by the matches left', function()
		assert.are_same(
			{{1, 2}, {1, 2}, {3, 4}, {3, 4}},
			rangesOf(SRR, makeEntries{{2, 0}, {2, 0}, {0, 2}, {0, 2}})
		)
		assert.are_same(
			{{1, 4}, {1, 4}, {1, 4}, {1, 4}},
			rangesOf(SRR, makeEntries{{1, 0}, {1, 0}, {0, 1}, {0, 1}})
		)
	end)

	it('plays every opponent once per cycle', function()
		assert.are_same(
			{{1, 4}, {1, 4}, {1, 4}, {1, 4}},
			rangesOf({type = 'roundrobin', cycles = 2}, makeEntries{{2, 0}, {2, 0}, {0, 2}, {0, 2}})
		)
	end)

	it('keeps the current placements possible when every result gives points', function()
		-- The last opponent has a match left that it may not play
		local points = {w = 3, d = 2, l = 1}
		assert.are_same(
			{{1, 1}, {2, 3}, {2, 3}},
			rangesOf(CLASSIC_SWISS, makeEntries({{3, 0}, {0, 3}, {0, 0, 1}}, points),
				{tiebreakerIds = POINTS_CONTEXT.tiebreakerIds, points = points})
		)
	end)

	it('ranks the match score by wins, then losses', function()
		assert.are_same(
			{{1, 3}, {1, 4}, {2, 4}, {1, 4}},
			rangesOf(CLASSIC_SWISS, makeEntries{{2, 0}, {1, 1}, {0, 2}, {1, 0}},
				{tiebreakerIds = {'full.disqualified', 'full.matchscore'}})
		)
	end)

	it('has no calculator for an unsupported first tiebreaker', function()
		local entries = makeEntries{{1, 0}, {0, 1}}
		assert.is_nil(rangesOf(SRR, entries, {tiebreakerIds = {'full.disqualified', 'full.matchwinrate'}}))
		assert.is_nil(rangesOf(SRR, entries, {tiebreakerIds = {'h2hcs.points'}}))
		assert.is_nil(rangesOf(SRR, entries, {tiebreakerIds = POINTS_CONTEXT.tiebreakerIds}))
		assert.is_not_nil(rangesOf(SRR, entries, {tiebreakerIds = {'full.points'}, points = POINTS}))
	end)

	it('has no ranges for more matches than the format has', function()
		assert.is_nil(rangesOf(SRR, makeEntries{{2, 1}, {0, 1}, {0, 0}}))
	end)

	describe('contains every final placement of a single round robin of four', function()
		local MATCHES = {{1, 2}, {3, 4}, {1, 3}, {2, 4}, {1, 4}, {2, 3}}
		-- Record index of each side per result: win and loss, draw, loss and win
		local RESULTS = {{1, 2}, {3, 3}, {2, 1}}

		---Records after the first matches of an outcome, which holds a result per match in base 3
		---@return integer[][]
		local function recordsAfter(outcome, matchCount)
			local records = Array.map(Array.range(1, 4), function() return {0, 0, 0} end)
			for index = 1, matchCount do
				local result = RESULTS[math.floor(outcome / 3 ^ (index - 1)) % 3 + 1]
				for side, opponent in ipairs(MATCHES[index]) do
					records[opponent][result[side]] = records[opponent][result[side]] + 1
				end
			end
			return records
		end

		for _, points in ipairs{POINTS, {w = 3, d = 2, l = 1}} do
			it('with win ' .. points.w .. ', draw ' .. points.d .. ' and loss ' .. points.l, function()
				local context = {tiebreakerIds = {'full.points'}, points = points}
				local opponents = Array.map(Array.range(1, 4), function() return {} end)
				local calculator = StandingsPlacementRange.calculator(SRR, opponents, context)
				---@cast calculator -nil
				for outcome = 0, 3 ^ #MATCHES - 1 do
					local final = Array.map(makeEntries(recordsAfter(outcome, #MATCHES), points), Operator.property('points'))
					for played = 0, #MATCHES, 2 do
						local ranges = assert(calculator:rangesFor(makeEntries(recordsAfter(outcome, played), points)))
						Array.forEach(ranges, function(range, opponent)
							local above = #Array.filter(final, function(value) return value > final[opponent] end)
							local atLeast = #Array.filter(final, function(value) return value >= final[opponent] end)
							assert.is_true(range[1] <= 1 + above and range[2] >= atLeast)
						end)
					end
				end
			end)
		end
	end)
end)
