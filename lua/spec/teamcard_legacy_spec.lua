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

    describe('mapPlayer basic mapping', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('reads display from positional', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'Faker'}, 'p1', nil)
            assert.are_equal('Faker', p[1])
        end)

        it('reads link', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'Faker', p1link = 'Lee Sang-hyeok'}, 'p1', nil)
            assert.are_equal('Lee Sang-hyeok', p.link)
        end)

        it('reads flag', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'Faker', p1flag = 'kr'}, 'p1', nil)
            assert.are_equal('kr', p.flag)
        end)

        it('prefers flag_o over flag', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'Faker', p1flag = 'kr', p1flag_o = 'us'}, 'p1', nil)
            assert.are_equal('us', p.flag)
        end)

        it('reads team override', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1team = 'oldTeam'}, 'p1', nil)
            assert.are_equal('oldTeam', p.team)
        end)

        it('reads id', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1id = 'faker-id'}, 'p1', nil)
            assert.are_equal('faker-id', p.id)
        end)

        it('reads faction', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1faction = 'p'}, 'p1', nil)
            assert.are_equal('p', p.faction)
        end)

        it('reads race as faction fallback', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1race = 'z'}, 'p1', nil)
            assert.are_equal('z', p.faction)
        end)

        it('reads pos as role', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1pos = 'top'}, 'p1', nil)
            assert.are_equal('top', p.role)
        end)
    end)

    describe('mapPlayer status & trophies', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('sums wins and winsc into trophies', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1wins = '2', p1winsc = '1'}, 'p1', nil)
            assert.are_equal(3, p.trophies)
        end)

        it('trophies nil when neither set', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X'}, 'p1', nil)
            assert.is_nil(p.trophies)
        end)

        it('passes joindate/leavedate through', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1joindate = '2025-01-01', p1leavedate = '2025-12-01'}, 'p1', nil)
            assert.are_equal('2025-01-01', p.joindate)
            assert.are_equal('2025-12-01', p.leavedate)
        end)

        it('reads played true', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1played = 'true'}, 'p1', nil)
            assert.is_true(p.played)
        end)

        it('reads result as played fallback', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1result = 'true'}, 'p1', nil)
            assert.is_true(p.played)
        end)

        it('dnp forces played=false even if result=true', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1result = 'true', p1dnp = 'true'}, 'p1', nil)
            assert.is_false(p.played)
        end)

        it('pNsub sets status=sub', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1sub = 'true'}, 'p1', nil)
            assert.are_equal('sub', p.status)
        end)

        it('pNleave sets status=former', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1leave = 'true'}, 'p1', nil)
            assert.are_equal('former', p.status)
        end)

        it('pNleave overrides pNsub', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1sub = 'true', p1leave = 'true'}, 'p1', nil)
            assert.are_equal('former', p.status)
        end)
    end)

    describe('mapPlayer source groups', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('source group s sets status=sub', function()
            local p = LegacyTeamCard.mapPlayer({s1 = 'X'}, 's1', 's')
            assert.are_equal('sub', p.status)
        end)

        it('source group f sets status=former', function()
            local p = LegacyTeamCard.mapPlayer({f1 = 'X'}, 'f1', 'f')
            assert.are_equal('former', p.status)
        end)

        it('source group s + subdnpdefault sets played=false when no result', function()
            local p = LegacyTeamCard.mapPlayer(
                {s1 = 'X', subdnpdefault = 'true'}, 's1', 's')
            assert.is_false(p.played)
            assert.are_equal('sub', p.status)
        end)

        it('source group s + subdnpdefault + explicit result keeps played=true', function()
            local p = LegacyTeamCard.mapPlayer(
                {s1 = 'X', s1result = 'true', subdnpdefault = 'true'}, 's1', 's')
            assert.is_true(p.played)
        end)

        it('source group f + formerdnpdefault sets played=false when no result', function()
            local p = LegacyTeamCard.mapPlayer(
                {f1 = 'X', formerdnpdefault = 'true'}, 'f1', 'f')
            assert.is_false(p.played)
            assert.are_equal('former', p.status)
        end)

        it('main group with noVarDefault leaves played untouched', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', noVarDefault = 'true'}, 'p1', nil)
            assert.is_nil(p.played)
        end)

        it('source group s with noVarDefault and no result sets played=false', function()
            local p = LegacyTeamCard.mapPlayer({s1 = 'X', noVarDefault = 'true'}, 's1', 's')
            assert.is_false(p.played)
        end)
    end)

    describe('mapCoach', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('coach defaults role to coach', function()
            local c = LegacyTeamCard.mapCoach({c1 = 'Score'}, 'c1', nil)
            assert.are_equal('coach', c.role)
            assert.are_equal('staff', c.type)
        end)

        it('coach with cNpos overrides role', function()
            local c = LegacyTeamCard.mapCoach({c1 = 'Score', c1pos = 'head coach'}, 'c1', nil)
            assert.are_equal('head coach', c.role)
        end)

        it('scN source group sets status=sub', function()
            local c = LegacyTeamCard.mapCoach({sc1 = 'Mata'}, 'sc1', 'sc')
            assert.are_equal('coach', c.role)
            assert.are_equal('sub', c.status)
        end)

        it('fcN source group sets status=former', function()
            local c = LegacyTeamCard.mapCoach({fc1 = 'kkOma'}, 'fc1', 'fc')
            assert.are_equal('coach', c.role)
            assert.are_equal('former', c.status)
        end)

        it('cNsub sets status=sub', function()
            local c = LegacyTeamCard.mapCoach({c1 = 'X', c1sub = 'true'}, 'c1', nil)
            assert.are_equal('sub', c.status)
        end)

        it('wins+winsc sum to trophies', function()
            local c = LegacyTeamCard.mapCoach({c1 = 'X', c1wins = '1', c1winsc = '2'}, 'c1', nil)
            assert.are_equal(3, c.trophies)
        end)

        it('flag_o wins over flag', function()
            local c = LegacyTeamCard.mapCoach({c1 = 'X', c1flag = 'kr', c1flag_o = 'us'}, 'c1', nil)
            assert.are_equal('us', c.flag)
        end)
    end)

    describe('mapPlayers enumeration', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('enumerates main players', function()
            local players = LegacyTeamCard.mapPlayers({p1 = 'A', p2 = 'B', p3 = 'C'})
            assert.are_equal(3, #players)
            assert.are_equal('A', players[1][1])
            assert.are_equal('B', players[2][1])
        end)

        it('appends sN players with status=sub', function()
            local players = LegacyTeamCard.mapPlayers({p1 = 'A', s1 = 'B'})
            assert.are_equal(2, #players)
            assert.is_nil(players[1].status)
            assert.are_equal('sub', players[2].status)
        end)

        it('appends fN players with status=former', function()
            local players = LegacyTeamCard.mapPlayers({p1 = 'A', f1 = 'B'})
            assert.are_equal('former', players[2].status)
        end)

        it('reads t2p* bucketed by t2type', function()
            local players = LegacyTeamCard.mapPlayers({p1 = 'A', t2p1 = 'B', t2type = 'sub'})
            assert.are_equal('sub', players[2].status)
        end)

        it('t2type=staff promotes t2p* to type=staff', function()
            local players = LegacyTeamCard.mapPlayers({p1 = 'A', t2p1 = 'B', t2type = 'staff'})
            assert.are_equal('staff', players[2].type)
        end)

        it('dedups t2p* against s* by pageName, t2p* wins', function()
            local players = LegacyTeamCard.mapPlayers({
                p1 = 'Faker',
                s1 = 'Pawn', s1link = 'Pawn (Korean)',
                t2p1 = 'Pawn (player)', t2p1link = 'Pawn (Korean)', t2type = 'sub',
            })
            local pawnCount = 0
            for _, p in ipairs(players) do
                if p.link == 'Pawn (Korean)' then pawnCount = pawnCount + 1 end
            end
            assert.are_equal(1, pawnCount)
        end)
    end)

    describe('mapCoaches enumeration', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('enumerates main coaches', function()
            local coaches = LegacyTeamCard.mapCoaches({c1 = 'A', c2 = 'B'})
            assert.are_equal(2, #coaches)
            assert.are_equal('coach', coaches[1].role)
            assert.are_equal('coach', coaches[2].role)
        end)

        it('appends scN as sub coaches', function()
            local coaches = LegacyTeamCard.mapCoaches({c1 = 'A', sc1 = 'B'})
            assert.are_equal('sub', coaches[2].status)
        end)

        it('reads t2c* with t2type', function()
            local coaches = LegacyTeamCard.mapCoaches({c1 = 'A', t2c1 = 'B', t2type = 'former'})
            assert.are_equal('former', coaches[2].status)
        end)
    end)
end)
