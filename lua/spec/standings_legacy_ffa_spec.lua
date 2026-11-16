--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Ffa', function()
	local StandingTableLegacyFfa = require('Module:Standings/Table/Legacy/Ffa')

	it('maps cutafter to collapseafter', function()
		assert.are_equal('16', StandingTableLegacyFfa.getStandardParameter{cutafter = '16'}.collapseafter)
	end)
end)
