--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Swiss', function()
	local StandingTableLegacySwiss = require('Module:Standings/Table/Legacy/Swiss')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')

	describe('tiebreakers', function()
		it('maps the minileague tiebreakers to ml', function()
			local tiebreakers = StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'minileague points',
				tiebreaker2 = 'minileague series%',
				tiebreaker3 = 'minileague games',
				tiebreaker4 = 'minileague games won',
			}
			assert.are_same({'ml.points', 'ml.matchwinrate', 'ml.gamediff', 'ml.gamewins'}, tiebreakers)
		end)

		it('only maps to valid tiebreakers', function()
			local tiebreakers = StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'points',
				tiebreaker2 = 'buchholz',
				tiebreaker3 = 'series',
				tiebreaker4 = 'diff',
				tiebreaker5 = 'games won',
				tiebreaker6 = 'games loss',
				tiebreaker7 = 'minileague points',
				tiebreaker8 = 'minileague series%',
				tiebreaker9 = 'minileague games',
				tiebreaker10 = 'minileague games won',
			}
			assert.are_equal(10, #tiebreakers)
			-- Errors on invalid tiebreakers
			for _, tiebreaker in ipairs(tiebreakers) do
				TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
			end
		end)

		it('errors on unknown tiebreakers', function()
			assert.error(function() StandingTableLegacySwiss.parseTiebreaker{tiebreaker1 = 'bogus'} end)
		end)
	end)

	describe('team input', function()
		it('maps r<round>bg<team> to r<round>bg on the opponent', function()
			local args = {
				rounds = '5',
				team1 = 'alpha',
				team2 = 'bravo',
				r3bg1 = 'up',
				r5bg1 = 'stayup',
				r4bg2 = 'down',
			}

			local alpha = StandingTableLegacySwiss.parseTeamInput(args, 1)
			assert.are_equal('alpha', alpha[1])
			assert.are_equal('up', alpha.r3bg)
			assert.are_equal('stayup', alpha.r5bg)
			assert.is_nil(alpha.r4bg)

			local bravo = StandingTableLegacySwiss.parseTeamInput(args, 2)
			assert.are_equal('down', bravo.r4bg)
			assert.is_nil(bravo.r3bg)
		end)

		it('ignores rounds beyond the number of rounds', function()
			local opponent = StandingTableLegacySwiss.parseTeamInput({rounds = '3', team1 = 'alpha', r4bg1 = 'up'}, 1)
			assert.is_nil(opponent.r4bg)
		end)
	end)

	describe('solo input', function()
		it('maps r<round>bg<player> to r<round>bg on the opponent', function()
			local args = {rounds = '5', player1 = 'Alpha', p2 = 'Bravo', r3bg1 = 'up', r4bg2 = 'down'}

			local alpha = StandingTableLegacySwiss.parseSoloInput(args, 1)
			assert.are_equal('Alpha', alpha[1])
			assert.are_equal('up', alpha.r3bg)
			assert.is_nil(alpha.r4bg)

			local bravo = StandingTableLegacySwiss.parseSoloInput(args, 2)
			assert.are_equal('down', bravo.r4bg)
			assert.is_nil(bravo.r3bg)
		end)
	end)
end)
