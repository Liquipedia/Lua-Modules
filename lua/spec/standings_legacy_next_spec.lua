--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Next', function()
	local StandingTableLegacyNext = require('Module:Standings/Table/Legacy/Next')

	describe('rounds', function()
		local function withMatches(matches, fn)
			local lpdbStub = stub(mw.ext.LiquipediaDB, 'lpdb', function() return matches end)
			local results = {fn()}
			lpdbStub:revert()
			return unpack(results)
		end

		local function match(id, date, round)
			return {match2id = id, date = date, match2bracketdata = {groupRoundIndex = round}}
		end

		local function idsByRound(matchesByRound, roundCount)
			local ids = {}
			for roundIndex = 1, roundCount do
				ids[roundIndex] = {}
				for _, roundMatch in ipairs(matchesByRound[roundIndex] or {}) do
					table.insert(ids[roundIndex], roundMatch.id)
				end
			end
			return ids
		end

		it('reads the rounds from the round index of the matches', function()
			local matchesByRound, roundCount = withMatches({
				match('a', '2024-01-01 12:00:00', 1),
				match('b', '2024-01-02 12:00:00', 2),
				match('c', '2024-01-03 12:00:00', 3),
			}, function() return StandingTableLegacyNext.fetchMatchesByRound{} end)

			assert.are_equal(3, roundCount)
			assert.are_same({{'a'}, {'b'}, {'c'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('uses the round end dates for matches without a round index', function()
			local matchesByRound, roundCount = withMatches({
				match('a', '2024-01-01 12:00:00'),
				match('b', '2024-01-02 12:00:00'),
				match('c', '2024-01-05 12:00:00'),
			}, function()
				return StandingTableLegacyNext.fetchMatchesByRound{
					round1edate = '2024-01-01 23:59',
					round2edate = '2024-01-02 23:59',
				}
			end)

			assert.are_equal(2, roundCount)
			assert.are_same({{'a'}, {'b', 'c'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('puts all matches in a single round if none have a round index', function()
			local matchesByRound, roundCount = withMatches({
				match('a', '2024-01-01 12:00:00'),
				match('b', '2024-01-02 12:00:00'),
			}, function() return StandingTableLegacyNext.fetchMatchesByRound{} end)

			assert.are_equal(1, roundCount)
			assert.are_same({{'a', 'b'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('computes the number of rounds', function()
			local matches = {{round = 2}, {round = 4}, {}, {round = 31}}
			assert.are_equal(4, StandingTableLegacyNext.computeRoundCount({}, matches, 0))
			assert.are_equal(6, StandingTableLegacyNext.computeRoundCount({rounds = '6'}, matches, 0))
			assert.are_equal(1, StandingTableLegacyNext.computeRoundCount({rounds = 'false'}, matches, 0))
			assert.are_equal(2, StandingTableLegacyNext.computeRoundCount({rounds = 'false'}, matches, 2))
			assert.are_equal(5, StandingTableLegacyNext.computeRoundCount({}, matches, 5))
		end)
	end)
end)
