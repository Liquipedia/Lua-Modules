--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Group', function()
	local StandingTableLegacyGroup = require('Module:Standings/Table/Legacy/Group')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')

	local NOW = 1700000000
	local DAY = 86400

	describe('tiebreakers', function()
		it('defaults to the legacy order', function()
			assert.are_same({
				'matchscore', 'gamediff', 'h2hlegacy.matchscore', 'h2hlegacy.gamediff', 'gamewins', 'gamelosses',
			}, StandingTableLegacyGroup.parseTiebreakers{})
		end)

		it('puts points first in the default order with show_p', function()
			assert.are_equal('points', StandingTableLegacyGroup.parseTiebreakers{show_p = 'true'}[1])
		end)

		it('only maps to valid tiebreakers', function()
			local tiebreakers = StandingTableLegacyGroup.parseTiebreakers{
				tiebreaker1 = 'points',
				tiebreaker2 = 'series',
				tiebreaker3 = 'series%',
				tiebreaker4 = 'series diff',
				tiebreaker5 = 'diff',
				tiebreaker6 = 'games won',
				tiebreaker7 = 'games loss',
				tiebreaker8 = 'head-to-head series',
				tiebreaker9 = 'head to head games',
			}
			assert.are_same({
				'points', 'matchscore', 'matchwinrate', 'matchdiff', 'gamediff', 'gamewins', 'gamelosses',
				'h2hlegacy.matchscore', 'h2hlegacy.gamediff',
			}, tiebreakers)
			for _, tiebreaker in ipairs(tiebreakers) do
				TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
			end
		end)

		it('errors on unknown tiebreakers', function()
			assert.error(function() StandingTableLegacyGroup.parseTiebreakers{tiebreaker1 = 'bogus'} end)
		end)
	end)

	describe('rounds', function()
		it('has a single final round without round dates', function()
			assert.are_same({{index = 0}}, StandingTableLegacyGroup.parseRounds({}, NOW))
		end)

		it('orders the rounds by their date and adds the final round after them', function()
			local rounds = StandingTableLegacyGroup.parseRounds({
				r1date = NOW - 2 * DAY,
				round2edate = NOW - 3 * DAY,
			}, NOW)
			assert.are_same({
				{index = 2, endTime = NOW - 3 * DAY},
				{index = 1, endTime = NOW - 2 * DAY},
				{index = 0},
			}, rounds)
		end)

		it('reads a round with both date and edate once', function()
			local rounds = StandingTableLegacyGroup.parseRounds({r1date = NOW - DAY, r1edate = NOW - DAY}, NOW)
			assert.are_same({{index = 1, endTime = NOW - DAY}, {index = 0}}, rounds)
		end)

		it('has no final round while a round is still to come', function()
			local rounds = StandingTableLegacyGroup.parseRounds({r1date = NOW - DAY, r2date = NOW + DAY}, NOW)
			assert.are_same({1, 2}, {rounds[1].index, rounds[2].index})
			assert.are_equal(2, #rounds)
		end)

		it('drops the rounds after edate and ends the final round at it', function()
			local rounds = StandingTableLegacyGroup.parseRounds({
				r1date = NOW - 3 * DAY,
				r2date = NOW - DAY,
				edate = NOW - 2 * DAY,
			}, NOW)
			assert.are_same({{index = 1, endTime = NOW - 3 * DAY}, {index = 0, endTime = NOW - 2 * DAY}}, rounds)
		end)

		it('assigns the matches to the first round ending after them', function()
			local rounds = {{index = 1, endTime = 100}, {index = 2, endTime = 200}, {index = 0}}
			local matchesByRound = StandingTableLegacyGroup.groupMatchesByRound(rounds, {
				{match2id = 'a', date = 50},
				{match2id = 'b', date = 100},
				{match2id = 'c', date = 150},
				{match2id = 'd', date = 300},
			})
			assert.are_same({'a', 'b'}, matchesByRound[1])
			assert.are_same({'c'}, matchesByRound[2])
			assert.are_same({'d'}, matchesByRound[3])
		end)

		it('assigns matches after the last round to it', function()
			local matchesByRound = StandingTableLegacyGroup.groupMatchesByRound(
				{{index = 1, endTime = 100}}, {{match2id = 'a', date = 300}}
			)
			assert.are_same({'a'}, matchesByRound[1])
		end)
	end)

	describe('team input', function()
		local rounds = {{index = 2, endTime = 100}, {index = 1, endTime = 200}, {index = 0}}

		it('maps the per round inputs to the rounds in date order', function()
			local args = {
				team1 = 'alpha',
				r1bg1 = 'up',
				round2bg1 = 'stay',
				bg1 = 'proceed',
				r2dq2 = 'true',
				team2 = 'bravo',
				dq2 = 'true',
			}

			local alpha = StandingTableLegacyGroup.parseTeamInput(args, 1, rounds)
			assert.are_same({'alpha', 'stay', 'up', 'proceed'}, {alpha[1], alpha.r1bg, alpha.r2bg, alpha.r3bg})
			assert.is_nil(alpha.dq)

			assert.are_equal(1, StandingTableLegacyGroup.parseTeamInput(args, 2, rounds).dq)
		end)

		it('applies the final round inputs to the last round without a final round', function()
			local alpha = StandingTableLegacyGroup.parseTeamInput(
				{team1 = 'alpha', bg1 = 'up', dq1 = 'true'}, 1, {{index = 1, endTime = 100}, {index = 2, endTime = 200}}
			)
			assert.are_equal('up', alpha.r2bg)
			assert.are_equal(2, alpha.dq)
		end)

		it('maps temp_p and temp_tie to adjustments from their round', function()
			local alpha = StandingTableLegacyGroup.parseTeamInput(
				{team1 = 'alpha', temp_p1 = '2', r1temp_p1 = '-1', temp_tie1 = '1'}, 1, rounds
			)
			assert.are_same({-1, 2, 1}, {alpha.r2points, alpha.r3points, alpha.r3tiebreaker})
			assert.is_nil(alpha.startingpoints)
		end)

		it('maps team<N>alias to the aliases of the opponent', function()
			assert.are_equal('alpha old;alpha older', StandingTableLegacyGroup.parseTeamInput(
				{team1 = 'alpha', team1alias = 'alpha old, alpha older'}, 1, rounds
			).aliases)
		end)
	end)

	describe('standard parameters', function()
		it('imports the opponents from the matches only if none are listed', function()
			assert.is_true(StandingTableLegacyGroup.getStandardParameter({}, {}).importopponents)
			assert.is_false(StandingTableLegacyGroup.getStandardParameter({}, {{}}).importopponents)
		end)

		it('is a group table that is exclusive by default', function()
			local parameters = StandingTableLegacyGroup.getStandardParameter({title = 'Group A'}, {})
			assert.are_same({'group', true, 'Group A'}, {parameters.tabletype, parameters.exclusive, parameters.title})
		end)

		it('maps the legacy points', function()
			assert.are_equal('win=3, draw=1, loss=0, 2-0=4',
				StandingTableLegacyGroup.getStandardParameter({['2-0_p'] = '1'}, {}).points)
		end)
	end)

	describe('classic', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

		before_each(function()
			TeamTemplateMock.setUp()
			stub(mw.ext.LiquipediaDB, 'lpdb', {})
			stub(mw.ext.LiquipediaDB, 'lpdb_standingstable')
			stub(mw.ext.LiquipediaDB, 'lpdb_standingsentry')
		end)

		after_each(function()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_standingstable:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_standingsentry:revert()
			TeamTemplateMock.tearDown()
		end)

		it('renders and stores a group table', function()
			local html = tostring(StandingTableLegacyGroup.classic{
				title = 'Group A',
				team1 = 'team liquid',
				team2 = 'mouz',
				pbg1 = 'up',
				pbg2 = 'down',
				tiebreaker1 = 'diff',
			})
			assert.is_truthy(html:find('standings-group', 1, true))
			assert.is_truthy(html:find('Group A', 1, true))
			---@diagnostic disable-next-line: undefined-field
			local storedTable = mw.ext.LiquipediaDB.lpdb_standingstable.calls[1].vals[2]
			assert.are_equal('league', storedTable.type)
		end)

		it('counts the adjustments in the standings', function()
			StandingTableLegacyGroup.classic{
				team1 = 'team liquid',
				team2 = 'mouz',
				temp_win_m2 = '1',
				temp_tie2 = '1',
			}
			---@diagnostic disable-next-line: undefined-field
			local entries = require('Module:Array').map(mw.ext.LiquipediaDB.lpdb_standingsentry.calls, function(call)
				return call.vals[2]
			end)
			local firstEntry = require('Module:Array').find(entries, function(entry) return entry.slotindex == 1 end)
			local scoreboard = require('Module:Json').parse(firstEntry.scoreboard)
			assert.are_equal('mouz', firstEntry.opponenttemplate:match('^mouz'))
			assert.are_same({3, 1}, {scoreboard.points, scoreboard.match.w})
		end)
	end)

	describe('adjustments', function()
		local rounds = {{index = 1, endTime = 100}, {index = 0}}

		it('maps the match and game record adjustments', function()
			assert.are_same({
				r1matchwins = 1,
				r1points = 3,
				r2matchdraws = 2,
				r2matchlosses = 1,
				r2gamewins = 3,
				r2gamelosses = 4,
			}, StandingTableLegacyGroup.parseAdjustments({
				r1temp_win_m1 = '1',
				temp_tie_m1 = '2',
				temp_lose_m1 = '1',
				temp_win_g1 = '3',
				temp_lose_g1 = '4',
				tie_p = '0',
			}, 1, rounds))
		end)

		it('counts the adjusted matches towards the points', function()
			assert.are_same(
				{r2matchwins = 2, r2matchdraws = 1, r2matchlosses = 1, r2points = 4},
				StandingTableLegacyGroup.parseAdjustments(
					{temp_win_m1 = '2', temp_tie_m1 = '1', temp_lose_m1 = '1', win_p = '2', lose_p = '-1'}, 1, rounds
				)
			)
		end)

		it('only reads the adjustments of the opponent', function()
			assert.are_same({}, StandingTableLegacyGroup.parseAdjustments({temp_p2 = '1', temp_p12 = '1'}, 1, rounds))
		end)

		it('errors on non numeric adjustments', function()
			assert.error(function() StandingTableLegacyGroup.parseAdjustments({temp_win_m1 = 'one'}, 1, rounds) end)
		end)
	end)
end)
