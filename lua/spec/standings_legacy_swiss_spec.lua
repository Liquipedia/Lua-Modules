--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Swiss', function()
	local StandingTableLegacySwiss = require('Module:Standings/Table/Legacy/Swiss')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')

	describe('tiebreakers', function()
		it('maps the h2h and minileague tiebreakers to h2hlegacy and ml', function()
			local tiebreakers = StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'h2h series',
				tiebreaker2 = 'h2h games',
				tiebreaker3 = 'minileague points',
				tiebreaker4 = 'minileague series%',
				tiebreaker5 = 'minileague games',
				tiebreaker6 = 'minileague games won',
			}
			assert.are_same({
				'h2hlegacy.matchscore', 'h2hlegacy.gamediff', 'ml.points', 'ml.matchwinrate', 'ml.gamediff', 'ml.gamewins',
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

		it('maps team<team>alias to the aliases of the opponent', function()
			local args = {
				team1 = 'alpha',
				team1alias = 'alpha old, alpha older',
				team2 = 'bravo',
				team2alias = 'bravo old',
				team3 = 'charlie',
			}

			assert.are_equal('alpha old;alpha older', StandingTableLegacySwiss.parseTeamInput(args, 1).aliases)
			assert.are_equal('bravo old', StandingTableLegacySwiss.parseTeamInput(args, 2).aliases)
			assert.is_nil(StandingTableLegacySwiss.parseTeamInput(args, 3).aliases)
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

	describe('points', function()
		it('uses the legacy defaults', function()
			assert.are_equal('win=3, draw=1, loss=0', StandingTableLegacySwiss.parsePoints{})
		end)

		it('maps win_p, tie_p and lose_p', function()
			assert.are_equal(
				'win=2, draw=0.5, loss=-1',
				StandingTableLegacySwiss.parsePoints{win_p = '2', tie_p = '0.5', lose_p = '-1'}
			)
		end)

		it('converts additive score points to fixed points of a win', function()
			assert.are_equal('win=3, draw=1, loss=0, 2-0=6', StandingTableLegacySwiss.parsePoints{['2-0_p'] = '3'})
			-- compares the scores as numbers
			assert.are_equal('win=3, draw=1, loss=0, 10-2=4', StandingTableLegacySwiss.parsePoints{['10-2_p'] = '1'})
			assert.are_equal(
				'win=2, draw=1, loss=0, 2-0=3.5',
				StandingTableLegacySwiss.parsePoints{win_p = '2', ['2-0_p'] = '1.5'}
			)
		end)

		it('converts additive score points to fixed points of a loss', function()
			assert.are_equal('win=3, draw=1, loss=0, 0-2=1', StandingTableLegacySwiss.parsePoints{['0-2_p'] = '1'})
			assert.are_equal(
				'win=3, draw=1, loss=-1, 1-2=0',
				StandingTableLegacySwiss.parsePoints{lose_p = '-1', ['1-2_p'] = '1'}
			)
		end)

		it('converts additive score points to fixed points of a draw', function()
			assert.are_equal(
				'win=3, draw=2, loss=0, 1-1=3',
				StandingTableLegacySwiss.parsePoints{tie_p = '2', ['1-1_p'] = '1'}
			)
		end)

		it('orders the score points deterministically', function()
			assert.are_equal(
				'win=3, draw=1, loss=0, 0-2=0, 1-1=1, 2-0=3, 2-1=3',
				StandingTableLegacySwiss.parsePoints{['2-1_p'] = '0', ['2-0_p'] = '0', ['1-1_p'] = '0', ['0-2_p'] = '0'}
			)
		end)

		it('ignores unrelated arguments', function()
			assert.are_equal(
				'win=3, draw=1, loss=0',
				StandingTableLegacySwiss.parsePoints{title = 'Swiss', ['2-0'] = '3', ['x-y_p'] = '3'}
			)
		end)

		it('errors on non numeric values', function()
			assert.error(function() StandingTableLegacySwiss.parsePoints{win_p = 'three'} end)
			assert.error(function() StandingTableLegacySwiss.parsePoints{['2-0_p'] = 'three'} end)
		end)

		it('is passed on as the points of the standard parameters', function()
			assert.are_equal(
				'win=3, draw=1, loss=0, 2-0=6',
				StandingTableLegacySwiss.getStandardParameter{['2-0_p'] = '3'}.points
			)
		end)
	end)

	describe('walkover games', function()
		it('maps walkover_win to walkovergames', function()
			assert.are_equal('2', StandingTableLegacySwiss.getStandardParameter{walkover_win = '2'}.walkovergames)
			assert.is_nil(StandingTableLegacySwiss.getStandardParameter{}.walkovergames)
		end)
	end)
end)
