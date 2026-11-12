--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Ffa', function()
	local StandingTableLegacyFfa = require('Module:Standings/Table/Legacy/Ffa')

	it('passes cutafter through', function()
		assert.are_equal('16', StandingTableLegacyFfa.getStandardParameter{cutafter = '16'}.cutafter)
	end)
end)
