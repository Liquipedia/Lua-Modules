--- Triple Comment to Enable our LLS Plugin
describe('TeamCard Legacy', function()
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
            local p = LegacyTeamCard.mapPlayer(
                {p1 = 'X', p1joindate = '2025-01-01', p1leavedate = '2025-12-01'}, 'p1', nil)
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

        it('pNsub=true + pNdnp=true: status=sub and played=false', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1sub = 'true', p1dnp = 'true'}, 'p1', nil)
            assert.are_equal('sub', p.status)
            assert.is_false(p.played)
        end)

        it('pNleave=true + pNdnp=true: status=former and played=false', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', p1leave = 'true', p1dnp = 'true'}, 'p1', nil)
            assert.are_equal('former', p.status)
            assert.is_false(p.played)
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

        it('main group with noVarDefault leaves played untouched', function()
            local p = LegacyTeamCard.mapPlayer({p1 = 'X', noVarDefault = 'true'}, 'p1', nil)
            assert.is_nil(p.played)
        end)

        it('source group s with noVarDefault and no result sets played=false', function()
            local p = LegacyTeamCard.mapPlayer({s1 = 'X', noVarDefault = 'true'}, 's1', 's')
            assert.is_false(p.played)
        end)

        it('source group f with noVarDefault leaves played untouched', function()
            local p = LegacyTeamCard.mapPlayer({f1 = 'X', noVarDefault = 'true'}, 'f1', 'f')
            assert.is_nil(p.played)
        end)

        it('source group s + pNsub=true: status=sub (redundant, no conflict)', function()
            local p = LegacyTeamCard.mapPlayer({s1 = 'X', s1sub = 'true'}, 's1', 's')
            assert.are_equal('sub', p.status)
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

    describe('mapCard', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('uses link over team for template', function()
            local card = LegacyTeamCard.mapCard({team = 'Display', link = 'Real Team'})
            assert.are_equal('Real Team', card[1])
        end)

        it('falls back to team if no link', function()
            local card = LegacyTeamCard.mapCard({team = 'Solo Team'})
            assert.are_equal('Solo Team', card[1])
        end)

        it('team2/team3 populate contenders with all three teams', function()
            local card = LegacyTeamCard.mapCard({
                team = 'A', team2 = 'B', team3 = 'C',
            })
            assert.is_nil(card[1])
            assert.are_same({'A', 'B', 'C'}, card.contenders)
        end)

        it('contender uses link if present', function()
            local card = LegacyTeamCard.mapCard({
                team = 'A', link = 'AReal',
                team2 = 'B', link2 = 'BReal',
            })
            assert.are_same({'AReal', 'BReal'}, card.contenders)
        end)

        it('qualification built from qualifier', function()
            local card = LegacyTeamCard.mapCard({team = 'A', qualifier = 'Invited'})
            assert.are_equal('invite', card.qualification.method)
        end)

        it('notes and inotes both populate notes list', function()
            local card = LegacyTeamCard.mapCard({team = 'A', notes = 'note A', inotes = 'note B'})
            assert.are_equal(2, #card.notes)
            assert.are_equal('note A', card.notes[1][1])
            assert.are_equal('note B', card.notes[2][1])
        end)

        it('aliases reads alsoknownas first then aliases', function()
            assert.are_equal('foo;bar',
                LegacyTeamCard.mapCard({team = 'A', alsoknownas = 'foo;bar', aliases = 'wrong'}).aliases)
            assert.are_equal('only-aliases',
                LegacyTeamCard.mapCard({team = 'A', aliases = 'only-aliases'}).aliases)
        end)

        it('combines players and coaches into one list', function()
            local card = LegacyTeamCard.mapCard({team = 'A', p1 = 'P', c1 = 'C'})
            assert.are_equal('P', card.players[1][1])
            assert.are_equal('C', card.players[2][1])
            assert.are_equal('staff', card.players[2].type)
        end)

        it('sets import=false unconditionally', function()
            local card = LegacyTeamCard.mapCard({team = 'A', import = 'true'})
            assert.is_false(card.import)
        end)
    end)

    describe('toggle folding', function()
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('folds zero toggles to defaults', function()
            local f = LegacyTeamCard._foldToggles({})
            assert.is_false(f.showPlayerInfo)
            assert.are_equal(0, f.extraPlayers)
            assert.are_same({}, f.notes)
        end)

        it('playerinfo=true sets showPlayerInfo', function()
            local f = LegacyTeamCard._foldToggles({{playerinfo = 'true'}})
            assert.is_true(f.showPlayerInfo)
        end)

        it('sums p_extra', function()
            local f = LegacyTeamCard._foldToggles({{p_extra = '2'}, {p_extra = '3'}})
            assert.are_equal(5, f.extraPlayers)
        end)

        it('collects notes in order, skipping empty', function()
            local f = LegacyTeamCard._foldToggles({{note = 'first'}, {note = ''}, {note = 'second'}})
            assert.are_same({'first', 'second'}, f.notes)
        end)
    end)

    describe('run — partition and malformed', function()
        local Template = require('Module:Template')
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        local function stashAll(entries)
            for _, e in ipairs(entries) do
                Template.stashReturnValue(e, 'LegacyTeamCard')
            end
        end

        it('with no stash, returns empty render without error', function()
            local out = LegacyTeamCard.run()
            assert.is_truthy(out)
        end)

        it('with malformed structure (no header, just cards), adds tracking category and renders', function()
            local TPParser = require('Module:TeamParticipants/Parse/Wiki')
            local stubParseMalformed = stub(TPParser, 'parseWikiInput', function()
                return {participants = {}}
            end)
            local addCategory = stub(mw.ext.TeamLiquidIntegration, 'add_category', function() end)
            stashAll({
                {team = 'A', __source = 'card'},
                {team = 'B', __source = 'card'},
            })
            local out = LegacyTeamCard.run()
            assert.is_truthy(out)
            assert.stub(addCategory).was.called_with('Pages with malformed Legacy TeamCard structure')
            addCategory:revert()
            stubParseMalformed:revert()
        end)
    end)

    describe('run — render and post-render side effects', function()
        local Template = require('Module:Template')
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('passes minimumplayers = defaultRowNumber + extraRows + sum(p_extra)', function()
            local TPParser = require('Module:TeamParticipants/Parse/Wiki')
            local captured
            local stubParse = stub(TPParser, 'parseWikiInput', function(args)
                captured = args
                return {participants = {}, expectedPlayerCount = tonumber(args.minimumplayers)}
            end)

            Template.stashReturnValue({__source = 'header'}, 'LegacyTeamCard')
            Template.stashReturnValue({__source = 'toggle', p_extra = '2'}, 'LegacyTeamCard')
            Template.stashReturnValue(
                {__source = 'card', team = 'A', defaultRowNumber = '5', extraRows = '1'}, 'LegacyTeamCard')

            LegacyTeamCard.run()
            assert.are_equal('8', tostring(captured.minimumplayers))

            stubParse:revert()
        end)

    end)

    describe('run — preprocessCard hook', function()
        local Template = require('Module:Template')
        local LegacyTeamCard = require('Module:TeamCard/Legacy')

        it('applies preprocessCard to each card before mapping', function()
            local TPParser = require('Module:TeamParticipants/Parse/Wiki')
            local captured
            local stubParse = stub(TPParser, 'parseWikiInput', function(args)
                captured = args
                return {participants = {}, expectedPlayerCount = 0}
            end)

            Template.stashReturnValue({__source = 'header'}, 'LegacyTeamCard')
            Template.stashReturnValue({__source = 'card', sub1 = 'X'}, 'LegacyTeamCard')

            LegacyTeamCard.run({
                preprocessCard = function(card)
                    if card.sub1 then card.p1 = card.sub1; card.p1sub = 'true'; card.sub1 = nil end
                    return card
                end,
            })

            -- The first opponent in captured should now have p1='X' as a sub-status player.
            assert.are_equal('X', captured[1].players[1][1])
            assert.are_equal('sub', captured[1].players[1].status)

            stubParse:revert()
        end)
    end)

    describe('integration', function()
        it('renders a representative legacy block via Module:Template stash', function()
            local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
            TeamTemplateMock.setUp()
            local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
            local LpdbPlacementStore = stub(mw.ext.LiquipediaDB, 'lpdb_placement', function() end)

            local Template = require('Module:Template')
            local LegacyTeamCard = require('Module:TeamCard/Legacy')

            Template.stashReturnValue({__source = 'toggle', playerinfo = 'true', p_extra = '1'}, 'LegacyTeamCard')
            Template.stashReturnValue({__source = 'header', cols = '4'}, 'LegacyTeamCard')
            Template.stashReturnValue({
                __source = 'card',
                team = 'Team Liquid',
                defaultRowNumber = '5',
                subdnpdefault = 'true',
                p1 = 'alexis',
                p2 = 'dodonut',
                p3 = 'meL',
                p4 = 'Noia',
                p5 = 'sarah',
                s1 = 'sub-player', s1result = 'true',
                c1 = 'Coach Name',
                qualifier = 'Invited',
            }, 'LegacyTeamCard')
            Template.stashReturnValue({
                __source = 'card',
                team = 'mouz',
                team2 = 'TBD',
                team3 = 'bds',
                defaultRowNumber = '5',
                qualifier = '[[Qualifier/2025|Qualifier]]',
            }, 'LegacyTeamCard')

            GoldenTest('teamcard_legacy', tostring(LegacyTeamCard.run()),
                [[<style>.collapsed > .should-collapse { display: block !important; }</style>]])

            LpdbQuery:revert()
            LpdbPlacementStore:revert()
            TeamTemplateMock.tearDown()
        end)
    end)
end)
