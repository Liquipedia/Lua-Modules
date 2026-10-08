--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Swiss', function()
	local StandingTableLegacySwiss = require('Module:Standings/Table/Legacy/Swiss')

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
end)
