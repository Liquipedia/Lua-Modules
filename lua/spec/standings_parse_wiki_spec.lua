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
				{'full.disqualified', 'full.points', 'h2h.matchwins', 'full.manual'},
				StandingsParseWiki.parseTiebreakers({tiebreakers = '["points", "h2h.matchwins"]'}, 'ffa')
			)
		end)
	end)
end)
