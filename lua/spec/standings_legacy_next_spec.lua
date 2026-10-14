--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Next', function()
	local StandingTableLegacyNext = require('Module:Standings/Table/Legacy/Next')

	describe('opponent input', function()
		it('reads solo, team and json opponents', function()
			local opponents = StandingTableLegacyNext.parseOpponents({
				p1 = 'Alpha',
				p1flag = 'se',
				p1link = 'Alpha (player)',
				t2 = 'bravo',
				team3 = 'charlie',
				opponent4 = '{"type":"literal","name":"Delta"}',
			}, 1)

			assert.are_equal(4, #opponents)
			assert.are_same({'solo', 'Alpha', 'se', 'Alpha (player)'},
				{opponents[1].type, opponents[1][1], opponents[1].flag, opponents[1].link})
			assert.are_same({'team', 'bravo'}, {opponents[2].type, opponents[2][1]})
			assert.are_same({'team', 'charlie'}, {opponents[3].type, opponents[3][1]})
			assert.are_same({'literal', 'Delta'}, {opponents[4].type, opponents[4].name})
		end)

		it('fills gaps with unprefixed opponents', function()
			local opponents = StandingTableLegacyNext.parseOpponents({
				'{"type":"team","template":"alpha"}',
				'bravo',
				team2 = 'charlie',
			}, 1)

			assert.are_equal(3, #opponents)
			assert.are_equal('alpha', opponents[1].template)
			assert.are_equal('charlie', opponents[2][1])
			assert.are_same({'team', 'bravo'}, {opponents[3].type, opponents[3][1]})
		end)

		it('reads the per opponent inputs', function()
			local opponents = StandingTableLegacyNext.parseOpponents({
				team1 = 'alpha',
				team1alias = 'alpha old, alpha older',
				temp_p1 = '3',
				temp_tie1 = '2',
				team2 = 'bravo',
				alias2 = 'bravo old',
			}, 1)

			assert.are_equal('alpha old;alpha older', opponents[1].aliases)
			assert.are_equal('3', opponents[1].startingpoints)
			assert.are_equal('2', opponents[1].tiebreaker)
			assert.are_equal('bravo old', opponents[2].aliases)
		end)

		it('imports opponents from matches only if none are listed', function()
			assert.is_true(StandingTableLegacyNext.getStandardParameter({}, {}).importopponents)
			assert.is_false(StandingTableLegacyNext.getStandardParameter({}, {{}}).importopponents)
			assert.is_true(StandingTableLegacyNext.getStandardParameter({importOpponents = 'true'}, {{}}).importopponents)
		end)

	end)

	describe('statuses', function()
		it('maps dq<N> to the first round and round<R>dq<N> to that round', function()
			local args = {dq1 = 'true', round3dq2 = 'true', round2dq3 = 'true', round4dq3 = 'true', round5dq4 = 'true'}
			assert.are_equal(1, StandingTableLegacyNext.parseDisqualifiedFromRound(args, 1, 4))
			assert.are_equal(3, StandingTableLegacyNext.parseDisqualifiedFromRound(args, 2, 4))
			assert.are_equal(2, StandingTableLegacyNext.parseDisqualifiedFromRound(args, 3, 4))
			assert.is_nil(StandingTableLegacyNext.parseDisqualifiedFromRound(args, 4, 4))
		end)

		it('maps round<R>bg<N> to r<R>bg and bg<N> to the final round', function()
			local args = {round2bg1 = 'up', bg1 = 'stayup', round3bg2 = 'down', bg2 = 'up', round4bg3 = 'up'}
			assert.are_same({r2bg = 'up', r3bg = 'stayup'}, StandingTableLegacyNext.parseDefiniteStatuses(args, 1, 3))
			assert.are_same({r3bg = 'down'}, StandingTableLegacyNext.parseDefiniteStatuses(args, 2, 3))
			assert.are_same({}, StandingTableLegacyNext.parseDefiniteStatuses(args, 3, 3))
		end)
	end)

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
