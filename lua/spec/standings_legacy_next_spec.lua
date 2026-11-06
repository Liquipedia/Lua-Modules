--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Next', function()
	local StandingTableLegacyNext = require('Module:Standings/Table/Legacy/Next')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')

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
			assert.are_same({3, 2}, {opponents[1].r1points, opponents[1].r1tiebreaker})
			assert.are_equal('bravo old', opponents[2].aliases)
		end)

		it('maps the manual adjustments to their rounds', function()
			assert.are_same({
				r1tiebreaker = 2,
				r2points = 1,
				r3points = 5,
				r3gamewins = 4,
			}, StandingTableLegacyNext.parseAdjustments({
				temp_tie1 = '2',
				round2temp_p1 = '1',
				temp_p1 = '2',
				round3temp_p1 = '3',
				temp_win_g1 = '4',
				round4temp_p1 = '9',
				temp_p2 = '7',
			}, 1, 3))
		end)

		it('counts the adjusted matches towards the points', function()
			assert.are_same(
				{r2matchwins = 2, r2matchdraws = 1, r2matchlosses = 1, r2points = 7},
				StandingTableLegacyNext.parseAdjustments({temp_win_m1 = '2', temp_tie_m1 = '1', temp_lose_m1 = '1'}, 1, 2)
			)
			assert.are_same(
				{r1matchwins = 2, r1points = 2},
				StandingTableLegacyNext.parseAdjustments({temp_win_m1 = '2', win_p = '1'}, 1, 1)
			)
		end)

		it('errors on non numeric adjustments', function()
			assert.error(function() StandingTableLegacyNext.parseAdjustments({temp_win_m1 = 'two'}, 1, 1) end)
		end)

		it('imports opponents from matches only if none are listed', function()
			assert.is_true(StandingTableLegacyNext.getStandardParameter({}, {}).importopponents)
			assert.is_false(StandingTableLegacyNext.getStandardParameter({}, {{}}).importopponents)
			assert.is_true(StandingTableLegacyNext.getStandardParameter({importOpponents = 'true'}, {{}}).importopponents)
		end)

		it('maps storeStanding to store', function()
			assert.is_nil(StandingTableLegacyNext.getStandardParameter({}, {}).store)
			assert.is_false(StandingTableLegacyNext.getStandardParameter({storeStanding = 'false'}, {}).store)
		end)
	end)

	describe('standard parameters', function()
		it('is a swiss table unless it is a group table', function()
			assert.are_equal('swiss', StandingTableLegacyNext.getStandardParameter({}, {}).tabletype)
			assert.are_equal('group', StandingTableLegacyNext.getStandardParameter({}, {}, 'group').tabletype)
		end)

		it('imports the matches unless import is disabled', function()
			assert.is_true(StandingTableLegacyNext.getStandardParameter({}, {}).import)
			assert.is_false(StandingTableLegacyNext.getStandardParameter({import = 'false'}, {}).import)
		end)

		it('ignores the overtime inputs', function()
			local parameters = StandingTableLegacyNext.getStandardParameter({show_otp = 'true', otw_p = '2'}, {})
			assert.is_false(parameters.overtime)
			assert.are_equal('win=3, draw=1, loss=0', parameters.points)
			assert.has_no.errors(function()
				StandingTableLegacyNext.getStandardParameter({show_otp = 'true', otw_p = '-', otl_p = '-'}, {})
			end)
		end)
	end)

	describe('format', function()
		it('infers gsl from 4 opponents and 5 matches', function()
			assert.are_equal('gsl', StandingTableLegacyNext.readFormat({}, 4, 5))
			assert.is_nil(StandingTableLegacyNext.readFormat({}, 4, 6))
			assert.is_nil(StandingTableLegacyNext.readFormat({}, 5, 5))
			assert.is_nil(StandingTableLegacyNext.readFormat({}, 8, 16))
		end)

		it('maps structure=gsl and ignores the other structures', function()
			assert.are_equal('gsl', StandingTableLegacyNext.readFormat({structure = 'gsl'}, 8, 0))
			assert.is_nil(StandingTableLegacyNext.readFormat({structure = 'other'}, 4, 5))
			assert.is_nil(StandingTableLegacyNext.readFormat({structure = 'swiss-3'}, 4, 5))
			assert.is_nil(StandingTableLegacyNext.readFormat({structure = 'roundRobin-2'}, 4, 5))
		end)

		it('errors on unknown structures', function()
			assert.error(function() StandingTableLegacyNext.readFormat({structure = 'swiss'}, 4, 5) end)
		end)

		it('produces a format the standings can read', function()
			local StandingsParseWiki = require('Module:Standings/Parse/Wiki')
			assert.are_same({type = 'swiss', winsToAdvance = 2, lossesToEliminate = 2},
				StandingsParseWiki.parseFormat({format = StandingTableLegacyNext.readFormat({}, 4, 5)}, 'group'))
		end)
	end)

	describe('points', function()
		it('defaults to 3 points for a win and 1 for a draw', function()
			assert.are_same({w = 3, d = 1, l = 0}, StandingTableLegacyNext.readResultPoints{})
		end)

		it('defaults the unset results to 0 with any of them set', function()
			assert.are_same({w = 2, d = 0, l = 0}, StandingTableLegacyNext.readResultPoints{win_p = '2'})
			assert.are_same({w = 0, d = 0, l = -1}, StandingTableLegacyNext.readResultPoints{lose_p = '-1'})
		end)

		it('only counts X-Y_p without win_p, tie_p and lose_p', function()
			assert.are_same({w = 0, d = 0, l = 0}, StandingTableLegacyNext.readResultPoints{['2-0_p'] = '3'})
			assert.are_same({w = 0, d = 0, l = 0}, StandingTableLegacyNext.readResultPoints{['0.5-0.5_p'] = '1'})
			assert.are_equal('win=0, draw=0, loss=0, 2-0=3',
				StandingTableLegacyNext.getStandardParameter({['2-0_p'] = '3'}, {}).points)
			assert.are_equal('win=1, draw=0, loss=0, 2-0=4',
				StandingTableLegacyNext.getStandardParameter({win_p = '1', ['2-0_p'] = '3'}, {}).points)
		end)

		it('reads X-Y_p with decimals', function()
			assert.are_equal('win=1, draw=0.5, loss=0, 0.5-0.5=0.75',
				StandingTableLegacyNext.getStandardParameter({win_p = '1', tie_p = '0.5', ['0.5-0.5_p'] = '0.25'}, {}).points)
		end)
	end)

	describe('statuses', function()
		it('maps dq<N> to the final round and round<R>dq<N> to that round', function()
			local args = {
				dq1 = 'true',
				round3dq2 = 'true',
				round2dq3 = 'true',
				round4dq3 = 'true',
				round5dq4 = 'true',
				round2dq5 = 'true',
				dq5 = 'true',
			}
			assert.are_equal(4, StandingTableLegacyNext.parseDisqualifiedFromRound(args, 1, 4))
			assert.are_equal(3, StandingTableLegacyNext.parseDisqualifiedFromRound(args, 2, 4))
			assert.are_equal(2, StandingTableLegacyNext.parseDisqualifiedFromRound(args, 3, 4))
			assert.is_nil(StandingTableLegacyNext.parseDisqualifiedFromRound(args, 4, 4))
			assert.are_equal(2, StandingTableLegacyNext.parseDisqualifiedFromRound(args, 5, 4))
		end)

		it('maps round<R>bg<N> to r<R>bg and bg<N> to the final round', function()
			local args = {round2bg1 = 'up', bg1 = 'stayup', round3bg2 = 'down', bg2 = 'up', round4bg3 = 'up'}
			assert.are_same({r2bg = 'up', r3bg = 'stayup'}, StandingTableLegacyNext.parseDefiniteStatuses(args, 1, 3))
			assert.are_same({r3bg = 'down'}, StandingTableLegacyNext.parseDefiniteStatuses(args, 2, 3))
			assert.are_same({}, StandingTableLegacyNext.parseDefiniteStatuses(args, 3, 3))
		end)
	end)

	describe('bgs', function()
		it('continues a pbg until the next one, starting with up', function()
			assert.are_equal('1-4=up,5-100=down', StandingTableLegacyNext.parseBgs({pbg5 = 'down'}, 8))
			assert.are_equal('1=up,2-3=stayup,4-8=down,9-100=up',
				StandingTableLegacyNext.parseBgs({pbg2 = 'stayup', pbg4 = 'down', pbg9 = 'up'}, 4))
		end)

		it('defaults to a quarter up, a quarter stayup and half down', function()
			assert.are_equal('1-2=up,3-4=stayup,5-100=down', StandingTableLegacyNext.parseBgs({}, 8))
			assert.are_equal('1-2=up,3-100=down', StandingTableLegacyNext.parseBgs({}, 4))
			assert.are_equal('1=up,2-100=down', StandingTableLegacyNext.parseBgs({}, 2))
			assert.are_equal('1-100=up', StandingTableLegacyNext.parseBgs({}, 1))
		end)

		it('produces bgs the standings can read', function()
			local StandingsParseWiki = require('Module:Standings/Parse/Wiki')
			local bgs = StandingsParseWiki.parseWikiBgs(StandingTableLegacyNext.parseBgs({}, 8))
			assert.are_same({'up', 'up', 'stayup', 'stayup', 'down'}, {bgs[1], bgs[2], bgs[3], bgs[4], bgs[5]})
			assert.are_equal('down', bgs[100])
			assert.is_nil(bgs[101])
		end)

		it('counts the opponents of the matches when importing them', function()
			local function opponent(name)
				return {type = 'team', name = name}
			end
			local matchRecords = {
				{match2opponents = {opponent('alpha'), opponent('bravo')}},
				{match2opponents = {opponent('alpha'), opponent('charlie')}},
				{match2opponents = {opponent('TBD'), opponent('')}},
				{match2opponents = {
					{type = 'solo', name = 'Delta', match2players = {{displayname = 'Delta'}}},
					{type = 'solo', name = 'TBD', match2players = {{displayname = 'TBD'}}},
				}},
			}
			assert.are_equal(1, StandingTableLegacyNext.countOpponents({{}}, matchRecords, false))
			assert.are_equal(4, StandingTableLegacyNext.countOpponents({}, matchRecords, true))
			assert.are_equal(5, StandingTableLegacyNext.countOpponents({{}, {}, {}, {}, {}}, matchRecords, true))
		end)
	end)

	describe('tiebreakers', function()
		it('maps the aliases', function()
			assert.are_same({
				'points', 'matchscore', 'gamediff', 'gamewins', 'gamelosses', 'ml.matchscore', 'ml.gamescore',
				'matchdiff', 'matchwinrate', 'matchwinrate', 'matchwinrate', 'gamewinrate', 'gamewinrate', 'gamewinrate',
			}, StandingTableLegacyNext.parseTiebreakers{
				tiebreaker1 = 'pts',
				tiebreaker2 = 'series',
				tiebreaker3 = 'diff',
				tiebreaker4 = 'games won',
				tiebreaker5 = 'games loss',
				tiebreaker6 = 'h2h series',
				tiebreaker7 = 'h2h games',
				tiebreaker8 = 'series diff',
				tiebreaker9 = 'series%',
				tiebreaker10 = 'series percentage',
				tiebreaker11 = 'series-percentage',
				tiebreaker12 = 'game%',
				tiebreaker13 = 'game percentage',
				tiebreaker14 = 'game-percentage',
			})
		end)

		it('maps the metric names and drops the implicit ones', function()
			assert.are_same({'matchwins', 'ml.gamescore', 'points'}, StandingTableLegacyNext.parseTiebreakers{
				tiebreaker1 = 'dq',
				tiebreaker2 = 'matchWins',
				tiebreaker3 = 'ml.gameScore',
				tiebreaker4 = 'points',
				tiebreaker5 = 'finalTiebreak',
			})
		end)

		it('defaults to the group table league tiebreakers', function()
			local defaults = {'matchscore', 'gamediff', 'ml.matchdiff', 'ml.gamescore', 'gamewins', 'gamelosses'}
			assert.are_same(defaults, StandingTableLegacyNext.parseTiebreakers{})
			table.insert(defaults, 1, 'points')
			assert.are_same(defaults, StandingTableLegacyNext.parseTiebreakers{show_p = 'true'})
			for _, tiebreaker in ipairs(defaults) do
				TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
			end
		end)

		it('errors on unknown tiebreakers', function()
			assert.error(function() StandingTableLegacyNext.parseTiebreakers{tiebreaker1 = 'bogus'} end)
			assert.error(function() StandingTableLegacyNext.parseTiebreakers{tiebreaker1 = 'h2h.matchScore'} end)
		end)
	end)

	describe('rounds', function()
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
			local matchesByRound, roundCount = StandingTableLegacyNext.groupMatchesByRound({}, {
				match('a', '2024-01-01 12:00:00', 1),
				match('b', '2024-01-02 12:00:00', 2),
				match('c', '2024-01-03 12:00:00', 3),
			})

			assert.are_equal(3, roundCount)
			assert.are_same({{'a'}, {'b'}, {'c'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('uses the round end dates for matches without a round index', function()
			local matchesByRound, roundCount = StandingTableLegacyNext.groupMatchesByRound({
				round1edate = '2024-01-01 23:59',
				round2edate = '2024-01-02 23:59',
			}, {
				match('a', '2024-01-01 12:00:00'),
				match('b', '2024-01-02 12:00:00'),
			})

			assert.are_equal(2, roundCount)
			assert.are_same({{'a'}, {'b'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('puts matches after the last round end date in a round of their own', function()
			local matchesByRound, roundCount = StandingTableLegacyNext.groupMatchesByRound({
				round1edate = '2024-01-01 23:59',
				round2edate = '2024-01-02 23:59',
			}, {
				match('a', '2024-01-01 12:00:00'),
				match('b', '2024-01-02 12:00:00'),
				match('c', '2024-01-05 12:00:00'),
				match('d', '2024-01-06 12:00:00'),
			})

			assert.are_equal(3, roundCount)
			assert.are_same({{'a'}, {'b'}, {'c', 'd'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('keeps indexed matches after the last round end date in their round', function()
			local matchesByRound, roundCount = StandingTableLegacyNext.groupMatchesByRound({
				round1edate = '2024-01-01 23:59',
				round2edate = '2024-01-02 23:59',
			}, {
				match('a', '2024-01-01 12:00:00', 1),
				match('b', '2024-01-02 12:00:00', 2),
				match('c', '2024-01-05 12:00:00', 2),
			})

			assert.are_equal(2, roundCount)
			assert.are_same({{'a'}, {'b', 'c'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('counts indexed matches after the last round end date beyond the dated rounds', function()
			local matchesByRound, roundCount = StandingTableLegacyNext.groupMatchesByRound({
				round1edate = '2024-01-01 23:59',
			}, {
				match('a', '2024-01-01 12:00:00', 1),
				match('b', '2024-01-05 12:00:00', 2),
			})

			assert.are_equal(2, roundCount)
			assert.are_same({{'a'}, {'b'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('puts matches in round end dates beyond the number of rounds in the final round', function()
			local matchesByRound, roundCount = StandingTableLegacyNext.groupMatchesByRound({
				rounds = '1',
				round1edate = '2024-01-01 23:59',
				round2edate = '2024-01-03 23:59',
			}, {
				match('a', '2024-01-01 12:00:00'),
				match('b', '2024-01-03 12:00:00'),
			})

			assert.are_equal(1, roundCount)
			assert.are_same({{'a', 'b'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('puts all matches in a single round if none have a round index', function()
			local matchesByRound, roundCount = StandingTableLegacyNext.groupMatchesByRound({}, {
				match('a', '2024-01-01 12:00:00'),
				match('b', '2024-01-02 12:00:00'),
			})

			assert.are_equal(1, roundCount)
			assert.are_same({{'a', 'b'}}, idsByRound(matchesByRound, roundCount))
		end)

		it('computes the number of rounds', function()
			local matches = {{round = 2}, {round = 4}, {}, {round = 31}}
			assert.are_equal(4, StandingTableLegacyNext.computeRoundCount({}, matches, 0))
			assert.are_equal(6, StandingTableLegacyNext.computeRoundCount({rounds = '6'}, matches, 0))
			assert.are_equal(1, StandingTableLegacyNext.computeRoundCount({rounds = 'false'}, matches, 0))
			assert.are_equal(2, StandingTableLegacyNext.computeRoundCount({rounds = 'false'}, matches, 2))
			assert.are_equal(1, StandingTableLegacyNext.computeRoundCount({rounds = '0'}, matches, 0))
			assert.are_equal(5, StandingTableLegacyNext.computeRoundCount({}, matches, 5))
		end)
	end)
end)
