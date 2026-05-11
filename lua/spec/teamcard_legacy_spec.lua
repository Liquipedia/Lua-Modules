--- Triple Comment to Enable our LLS Plugin
describe('TeamCard Legacy', function()
    local LegacyTeamCard = require('Module:TeamCard/Legacy')

    it('module loads', function()
        assert.is_table(LegacyTeamCard)
        assert.is_function(LegacyTeamCard.run)
    end)

    describe('parseQualifier', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('returns nil for nil input', function()
            assert.is_nil(LegacyTeamCard.parseQualifier(nil))
        end)

        it('parses plain text as method=qual type=other', function()
            local q = LegacyTeamCard.parseQualifier('Foo Bar')
            assert.are_same({method = 'qual', type = 'other', text = 'Foo Bar'}, q)
        end)

        it('detects "Invited" as method=invite', function()
            local q = LegacyTeamCard.parseQualifier('Invited')
            assert.are_same({method = 'invite', type = 'other', text = 'Invited'}, q)
        end)

        it('detects "invite" case-insensitively', function()
            local q = LegacyTeamCard.parseQualifier('invite via league')
            assert.are_equal('invite', q.method)
            assert.are_equal('other', q.type)
            assert.are_equal('invite via league', q.text)
        end)

        it('parses internal link as method=qual type=tournament when tournament resolves', function()
            local stubTournament = stub(require('Module:Tournament'), 'getTournament',
                function() return {pageName = 'Foo_Bar/2022'} end)
            local q = LegacyTeamCard.parseQualifier('[[Foo_Bar/2022|Qualifier]]')
            assert.are_same({method = 'qual', type = 'tournament', page = 'Foo_Bar/2022', text = 'Qualifier'}, q)
            stubTournament:revert()
        end)

        it('parses internal link as method=qual type=internal when tournament does not resolve', function()
            local stubTournament = stub(require('Module:Tournament'), 'getTournament', function() return nil end)
            local q = LegacyTeamCard.parseQualifier('[[Some_Page|Some Text]]')
            assert.are_same({method = 'qual', type = 'internal', page = 'Some_Page', text = 'Some Text'}, q)
            stubTournament:revert()
        end)

        it('parses external link as method=qual type=external', function()
            local q = LegacyTeamCard.parseQualifier('[https://foo.bar Foo Bar]')
            assert.are_same({method = 'qual', type = 'external', url = 'https://foo.bar', text = 'Foo Bar'}, q)
        end)

        it('handles relative internal link', function()
            local stubTournament = stub(require('Module:Tournament'), 'getTournament', function() return nil end)
            local q = LegacyTeamCard.parseQualifier('[[/Qualifier|Qual]]')
            assert.are_equal('internal', q.type)
            -- exact page resolved relative to current page; check it begins with the current page name
            assert.is_truthy(q.page)
            stubTournament:revert()
        end)
    end)
end)
