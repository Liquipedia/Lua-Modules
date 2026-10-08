--- Triple Comment to Enable our LLS Plugin
describe('Standings Tiebreaker HeadToHead', function()
	local HeadToHead = require('Module:Standings/Tiebreaker/HeadToHead')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')
	local Array = require('Module:Array')

	local tiebreaker = TiebreakerFactory.tiebreakerFromId('h2h.matchdiff')

	---@param result {[1]: string, [2]: string, draw: boolean?}
	---@param index integer
	---@return table
	local function makeMatch(result, index)
		local isDraw = result.draw == true
		return {
			matchId = 'M' .. index,
			finished = true,
			winner = isDraw and 0 or 1,
			opponents = {
				{type = 'literal', name = result[1], status = 'S', placement = 1},
				{type = 'literal', name = result[2], status = 'S', placement = isDraw and 1 or 2},
			},
			games = {},
		}
	end

	---Builds the opponents with the matches they played. The first name of a result won against the second,
	---or drew if marked as such.
	---@param names string[]
	---@param results {[1]: string, [2]: string, draw: boolean?}[]
	---@return table[]
	local function makeOpponents(names, results)
		local matches = Array.map(results, makeMatch)
		return Array.map(names, function(name)
			return {
				opponent = {type = 'literal', name = name},
				points = 0,
				matches = Array.filter(matches, function(match)
					return match.opponents[1].name == name or match.opponents[2].name == name
				end),
				matchPoints = {},
				match = {w = 0, d = 0, l = 0},
				extradata = {additionalStatsValues = {}},
			}
		end)
	end

	---@param groups table[][]
	---@return string[][]
	local function namesOf(groups)
		return Array.map(groups, function(group)
			return Array.map(group, function(opponent) return opponent.opponent.name end)
		end)
	end

	it('orders opponents that each beat the ones below', function()
		local opponents = makeOpponents({'C', 'A', 'B'}, {{'A', 'B'}, {'A', 'C'}, {'B', 'C'}})

		assert.are_same({{'A'}, {'B'}, {'C'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('resolves only one pass, leaving the middle as one group', function()
		local opponents = makeOpponents({'A', 'B', 'C', 'D'}, {
			{'A', 'B'}, {'A', 'C'}, {'A', 'D'},
			{'B', 'D'}, {'C', 'D'},
			{'B', 'C'},
		})

		-- B and C are split by a second pass, not by this one
		assert.are_same({{'A'}, {'B', 'C'}, {'D'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('leaves a cycle as one group', function()
		local opponents = makeOpponents({'A', 'B', 'C'}, {{'A', 'B'}, {'B', 'C'}, {'C', 'A'}})

		assert.are_same({{'A', 'B', 'C'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('puts multiple tops in one group', function()
		local opponents = makeOpponents({'A', 'B', 'C'}, {{'A', 'B', draw = true}, {'A', 'C'}, {'B', 'C'}})

		assert.are_same({{'A', 'B'}, {'C'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('puts multiple bottoms in one group', function()
		local opponents = makeOpponents({'A', 'B', 'C'}, {{'A', 'B'}, {'A', 'C'}, {'B', 'C', draw = true}})

		assert.are_same({{'A'}, {'B', 'C'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('counts pairs that never played as equal', function()
		local opponents = makeOpponents({'A', 'B', 'C'}, {{'A', 'B'}})

		-- C is equal to both A and B, so it is neither on top nor at the bottom
		assert.are_same({{'A'}, {'C'}, {'B'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('keeps an opponent that is equal to everyone in the middle', function()
		local opponents = makeOpponents({'A', 'B', 'C'}, {{'A', 'B', draw = true}, {'A', 'C', draw = true}, {'B', 'C'}})

		assert.are_same({{'B'}, {'A'}, {'C'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('has no effect if nobody played each other', function()
		local opponents = makeOpponents({'B', 'A', 'C'}, {})

		assert.are_same({{'B', 'A', 'C'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('ignores matches against opponents that are not part of the tie', function()
		local opponents = makeOpponents({'A', 'B', 'C'}, {{'C', 'A'}, {'C', 'B'}, {'A', 'B', draw = true}})

		-- C is not tied with the other two
		assert.are_same({{'A', 'B'}}, namesOf(HeadToHead.resolve(Array.sub(opponents, 1, 2), tiebreaker)))
	end)

	it('keeps the order of the input within a group', function()
		local opponents = makeOpponents({'D', 'C', 'B', 'A'}, {{'A', 'C'}, {'A', 'D'}, {'B', 'C'}, {'B', 'D'}})

		assert.are_same({{'B', 'A'}, {'D', 'C'}}, namesOf(HeadToHead.resolve(opponents, tiebreaker)))
	end)

	it('returns the original opponents', function()
		local opponents = makeOpponents({'A', 'B', 'C'}, {{'A', 'B'}, {'A', 'C'}, {'B', 'C'}})

		local groups = HeadToHead.resolve(opponents, tiebreaker)

		assert.is_true(rawequal(opponents[1], groups[1][1]))
		assert.is_true(rawequal(opponents[2], groups[2][1]))
		assert.is_true(rawequal(opponents[3], groups[3][1]))
		-- The scoped copies are not leaked into the opponents
		assert.are_same({w = 0, d = 0, l = 0}, opponents[1].match)
	end)

	it('works with other tiebreakers than the match diff', function()
		local matchWins = TiebreakerFactory.tiebreakerFromId('h2h.matchwins')
		local opponents = makeOpponents({'A', 'B'}, {{'A', 'B', draw = true}})

		assert.are_same({{'A', 'B'}}, namesOf(HeadToHead.resolve(opponents, matchWins)))

		opponents = makeOpponents({'A', 'B'}, {{'B', 'A'}})
		assert.are_same({{'B'}, {'A'}}, namesOf(HeadToHead.resolve(opponents, matchWins)))
	end)
end)
