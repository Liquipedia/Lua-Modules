--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Swiss', function()
	local StandingTableLegacySwiss = require('Module:Standings/Table/Legacy/Swiss')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')

	describe('tiebreakers', function()
		it('maps the h2h and minileague tiebreakers', function()
			local tiebreakers = StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'h2h series',
				tiebreaker2 = 'h2h games',
				tiebreaker3 = 'minileague points',
				tiebreaker4 = 'minileague series%',
				tiebreaker5 = 'minileague games',
				tiebreaker6 = 'minileague games won',
			}
			assert.are_same({
				'h2h.matchdiff', 'h2h.gamediff', 'ml.points', 'ml.matchwinrate', 'ml.gamediff', 'ml.gamewins',
			}, tiebreakers)
		end)

		it('only maps to valid tiebreakers', function()
			local tiebreakers = StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'points',
				tiebreaker2 = 'buchholz',
				tiebreaker3 = 'series',
				tiebreaker4 = 'diff',
				tiebreaker5 = 'games won',
				tiebreaker6 = 'games loss',
				tiebreaker7 = 'h2h series',
				tiebreaker8 = 'h2h games',
				tiebreaker9 = 'minileague points',
				tiebreaker10 = 'minileague series%',
				tiebreaker11 = 'minileague games',
				tiebreaker12 = 'minileague games won',
			}
			assert.are_equal(12, #tiebreakers)
			for _, tiebreaker in ipairs(tiebreakers) do
				assert.has_no.errors(function() TiebreakerFactory.validateAndNormalizeInput(tiebreaker) end)
			end
		end)

		it('errors on unknown tiebreakers', function()
			assert.error(function() StandingTableLegacySwiss.parseTiebreaker{tiebreaker1 = 'bogus'} end)
		end)
	end)
end)
