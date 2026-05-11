--- Triple Comment to Enable our LLS Plugin
describe('TeamCard Legacy', function()
    local LegacyTeamCard = require('Module:TeamCard/Legacy')

    it('module loads', function()
        assert.is_table(LegacyTeamCard)
        assert.is_function(LegacyTeamCard.run)
    end)
end)
