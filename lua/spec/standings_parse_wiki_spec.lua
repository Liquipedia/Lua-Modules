--- Triple Comment to Enable our LLS Plugin
describe('Standings Wiki Parser', function()
	local StandingsParseWiki = require('Module:Standings/Parse/Wiki')

	describe('disqualifications', function()
		it('reads dq input as the first round of disqualification', function()
			assert.are_equal(1, StandingsParseWiki.parseDisqualifiedFromRound('true'))
			assert.are_equal(1, StandingsParseWiki.parseDisqualifiedFromRound(true))
			assert.are_equal(2, StandingsParseWiki.parseDisqualifiedFromRound('2'))
			assert.are_equal(3, StandingsParseWiki.parseDisqualifiedFromRound(3))
			assert.is_nil(StandingsParseWiki.parseDisqualifiedFromRound('false'))
			assert.is_nil(StandingsParseWiki.parseDisqualifiedFromRound(''))
			assert.is_nil(StandingsParseWiki.parseDisqualifiedFromRound(nil))
		end)

		it('stores the disqualification round on the parsed opponent', function()
			local dqAll = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Alpha', dq = 'true'}, 2)
			local dqFromTwo = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Bravo', dq = '2'}, 2)
			local notDq = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Charlie'}, 2)

			assert.are_equal(1, dqAll.disqualifiedFromRound)
			assert.are_equal(2, dqFromTwo.disqualifiedFromRound)
			assert.is_nil(notDq.disqualifiedFromRound)
		end)
	end)

	describe('definite statuses', function()
		it('reads r<round>bg inputs keyed by the round they apply from', function()
			assert.are_same({[3] = 'up'}, StandingsParseWiki.parseDefiniteStatuses({r3bg = 'up'}, 5))
			assert.are_same(
				{[3] = 'stayup', [5] = 'up'},
				StandingsParseWiki.parseDefiniteStatuses({r3bg = 'stayup', r5bg = 'up', r1 = '3'}, 5)
			)
		end)

		it('ignores empty values and rounds beyond the number of rounds', function()
			assert.are_same({[2] = 'down'}, StandingsParseWiki.parseDefiniteStatuses({r1bg = '', r2bg = 'down'}, 3))
			assert.are_same({[1] = 'up'}, StandingsParseWiki.parseDefiniteStatuses({r1bg = 'up', r4bg = 'down'}, 3))
		end)

		it('returns nil when there are none', function()
			assert.is_nil(StandingsParseWiki.parseDefiniteStatuses({}, 3))
			assert.is_nil(StandingsParseWiki.parseDefiniteStatuses({r1bg = '', bg = 'up'}, 3))
			assert.is_nil(StandingsParseWiki.parseDefiniteStatuses({r4bg = 'up'}, 3))
		end)

		it('stores the definite statuses on the parsed opponent without affecting round input', function()
			local withStatuses = StandingsParseWiki.parseWikiOpponent(
				{type = 'literal', 'Alpha', r1 = '3', r2 = '1', r3bg = 'up', r4bg = 'stay'}, 3)
			local without = StandingsParseWiki.parseWikiOpponent({type = 'literal', 'Bravo', r1 = '3'}, 3)

			assert.are_same({[3] = 'up'}, withStatuses.definiteStatuses)
			assert.are_equal(3, withStatuses.rounds[1].scoreboard.points)
			assert.are_equal(1, withStatuses.rounds[2].scoreboard.points)
			assert.is_nil(withStatuses.rounds[3].scoreboard.points)
			assert.is_nil(without.definiteStatuses)
		end)
	end)

	describe('tiebreakers', function()
		it('always puts the disqualified tiebreaker first and manual last', function()
			assert.are_same(
				{'full.disqualified', 'full.points', 'full.manual'},
				StandingsParseWiki.parseTiebreakers({}, 'ffa')
			)
			assert.are_same(
				{'full.disqualified', 'full.matchdiff', 'full.manual'},
				StandingsParseWiki.parseTiebreakers({}, 'swiss')
			)
			assert.are_same(
				{'full.disqualified', 'full.matchdiff', 'ml.matchwins', 'full.manual'},
				StandingsParseWiki.parseTiebreakers({tiebreakers = '["matchdiff", "ml.matchwins"]'}, 'swiss')
			)
		end)

		it('accepts ml tiebreakers for swiss tables', function()
			assert.are_same(
				{'full.disqualified', 'full.matchdiff', 'ml.gamediff', 'full.manual'},
				StandingsParseWiki.parseTiebreakers(
					{tiebreakers = '["matchdiff", "ml.gamediff"]'}, 'swiss'
				)
			)
		end)

		it('rejects ml tiebreakers for ffa tables', function()
			assert.error(function()
				StandingsParseWiki.parseTiebreakers({tiebreakers = '["ml.points"]'}, 'ffa')
			end)
		end)
	end)
end)
