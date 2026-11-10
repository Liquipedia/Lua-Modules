--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Group Slot', function()
	local Array = require('Module:Array')
	local StandingTableLegacyGroupSlot = require('Module:Standings/Table/Legacy/GroupSlot')

	local CONFIG = StandingTableLegacyGroupSlot.CONFIG
	local OPT_IN_CONFIG = StandingTableLegacyGroupSlot.POINTS_OPT_IN_CONFIG

	local TEAM_LIQUID = '<span class="team-template-team-standard" data-highlighting-class="Team Liquid">'
		.. '<span class="team-template-image-icon">[[File:Team_Liquid_2020_lightmode.png|100x50px|link=Team Liquid]]'
		.. '</span> <span class="team-template-text">[[Team Liquid|Team Liquid]]</span></span>'
	local PLAYER_WITH_TEAM = '<span style="white-space:nowrap"><span class="team-template-team-part">'
		.. '<div class="block-team flipped"><span class="team-template-image-icon">'
		.. '[[File:Virtus.pro allmode.png|100x50px|link=Virtus.pro]]</span></div></span>'
		.. '<span class="inline-player" style="white-space:pre"><span class="flag">'
		.. '[[File:pl_hd.png|36x24px|Poland|link=]]</span>&nbsp;[[Av3k (player)|Av3k]]</span></span>'

	describe('opponents', function()
		local function teamWithName(name, page)
			return '<span class="team-template-team-short" data-highlighting-class="' .. name .. '">'
				.. '<span class="team-template-image-icon">[[File:X.png|100x50px|link=' .. page .. ']]</span>'
				.. ' <span class="team-template-text">[[' .. page .. '|' .. name .. ']]</span></span>'
		end

		it('reads the team of an expanded team template', function()
			assert.are_same({type = 'team', template = 'team liquid'}, StandingTableLegacyGroupSlot.parseOpponent(TEAM_LIQUID))
		end)

		it('takes the page of the team, not its shown name', function()
			assert.are_same(
				{type = 'team', template = 'k23 (counter-strike team)'},
				StandingTableLegacyGroupSlot.parseOpponent(teamWithName('k23', 'K23_(Counter-Strike_team)'))
			)
			assert.are_same(
				{type = 'team', template = 'texas a&m university'},
				StandingTableLegacyGroupSlot.parseOpponent(teamWithName('TAMU', 'Texas A&amp;M University'))
			)
		end)

		it('takes the page of an icon only team from its image', function()
			assert.are_same({type = 'team', template = 'redemption esports porto alegre'},
				StandingTableLegacyGroupSlot.parseOpponent(
					'<span class="team-template-team-icon" data-highlighting-class="Redemption POA">'
					.. '<span class="team-template-image-icon">[[File:R.png|100x50px|link=Redemption eSports Porto Alegre]]'
					.. '</span></span> [[Redemption eSports Porto Alegre|Redemption POA]]'
				))
		end)

		it('reads the name, link, flag and team of an expanded player', function()
			assert.are_same(
				{type = 'solo', 'Av3k', link = 'Av3k (player)', flag = 'pl', team = 'virtus.pro'},
				StandingTableLegacyGroupSlot.parseOpponent(PLAYER_WITH_TEAM)
			)
		end)

		it('reads a player with a team icon after them', function()
			local opponent = StandingTableLegacyGroupSlot.parseOpponent('<span class="inline-player"><span class="flag">'
				.. '[[File:au_hd.png|36x24px|Australia|link=]]</span>&nbsp;[[Hobbit]]</span> '
				.. teamWithName('Esper', 'Team Esper'))
			assert.are_same({type = 'solo', 'Hobbit', link = 'Hobbit', flag = 'au', team = 'team esper'}, opponent)
		end)

		it('reads a player without a team, and flags with a space', function()
			local opponent = StandingTableLegacyGroupSlot.parseOpponent('<span class="inline-player"><span class="flag">'
				.. '[[File:gb-eng hd.png|36x24px|England|link=]]</span>&nbsp;[[Rapha]]</span>')
			assert.are_same({type = 'solo', 'Rapha', link = 'Rapha', flag = 'gb-eng'}, opponent)
		end)

		it('reads a flag followed by a name as a player', function()
			assert.are_same({type = 'solo', 'Dog', flag = 'us'}, StandingTableLegacyGroupSlot.parseOpponent(
				'<span class="flag">[[File:us_hd.png|36x24px|United States|link=Category:United States]]</span> Dog'
			))
		end)

		it('falls back to a literal of the text', function()
			assert.are_same(
				{type = 'literal', name = 'Some Team'},
				StandingTableLegacyGroupSlot.parseOpponent('<b>[[Some Team (org)|Some Team]]</b>')
			)
		end)
	end)

	describe('points', function()
		it('scores 3 for a win and 1 for a draw by default', function()
			assert.are_equal(10, StandingTableLegacyGroupSlot.parsePoints({}, {win_m = '3', tie_m = '1', lose_m = '2'}, CONFIG))
		end)

		it('reads the points of the start before the slot', function()
			assert.are_equal(4, StandingTableLegacyGroupSlot.parsePoints({win_p = '2'}, {win_m = '2', win_p = '5'}, CONFIG))
			assert.are_equal(10, StandingTableLegacyGroupSlot.parsePoints({}, {win_m = '2', win_p = '5'}, CONFIG))
		end)

		it('scores the overtime results and loss points', function()
			assert.are_equal(
				3 + 2 + 1 - 2,
				StandingTableLegacyGroupSlot.parsePoints(
					{loss_p = '-1'}, {win_m = '1', ot_win_m = '1', ot_lose_m = '1', lose_m = '2'}, CONFIG
				)
			)
		end)

		it('shows overwrite_p in place of the points', function()
			assert.are_equal(7, StandingTableLegacyGroupSlot.parsePoints({}, {win_m = '5', overwrite_p = '7'}, CONFIG))
		end)

		it('counts temp_p only where legacy did', function()
			local slot = {win_m = '1', temp_p = '-2'}
			assert.are_equal(3, StandingTableLegacyGroupSlot.parsePoints({}, slot, CONFIG))
			assert.are_equal(1, StandingTableLegacyGroupSlot.parsePoints({}, slot, OPT_IN_CONFIG))
		end)

		it('errors on non numeric input', function()
			assert.error(function() StandingTableLegacyGroupSlot.parsePoints({}, {win_m = 'W'}, CONFIG) end)
		end)

		it('shows the points by default or only with show_p, depending on the wiki', function()
			assert.is_true(StandingTableLegacyGroupSlot.pointsShown({}, {{}}, CONFIG))
			assert.is_false(StandingTableLegacyGroupSlot.pointsShown({show_p = 'false'}, {{}}, CONFIG))
			assert.is_false(StandingTableLegacyGroupSlot.pointsShown({}, {{show_p = 'false'}}, CONFIG))
			assert.is_false(StandingTableLegacyGroupSlot.pointsShown({}, {{}}, OPT_IN_CONFIG))
			assert.is_true(StandingTableLegacyGroupSlot.pointsShown({show_p = 'true'}, {{}}, OPT_IN_CONFIG))
		end)
	end)

	describe('record', function()
		it('adds the overtime results to the match record', function()
			assert.are_same(
				{matchwins = 3, matchdraws = 1, matchlosses = 2, gamewins = 7, gamelosses = 4},
				StandingTableLegacyGroupSlot.parseRecord(
					{win_m = '2', ot_win_m = '1', tie_m = '1', lose_m = '1', ot_lose_m = '1', w_map = '7', l_map = '4'}
				)
			)
		end)

		it('reads drawn games', function()
			assert.are_same({gamewins = 8, gamedraws = 1, gamelosses = 3},
				StandingTableLegacyGroupSlot.parseRecord({win_g = '8', tie_g = '1', lose_g = '3'}))
		end)

		it('reads the rounds, or the battles of pokemon', function()
			assert.are_same({roundwins = 13, roundlosses = 9},
				StandingTableLegacyGroupSlot.parseRecord({win_r = '13', lose_r = '9'}))
			assert.are_same({roundwins = 5, roundlosses = 2},
				StandingTableLegacyGroupSlot.parseRecord({win_b = '5', lose_b = '2'}))
		end)
	end)

	describe('order', function()
		it('keeps the row order, also against the points', function()
			assert.are_same({-1, -2, -3}, StandingTableLegacyGroupSlot.parseOrder{
				{place = 1, points = 3}, {place = 2, points = 6}, {place = 3, points = 0},
			})
		end)

		it('shares a place between consecutive rows with the same place and points', function()
			assert.are_same({-1, -1, -3, -4}, StandingTableLegacyGroupSlot.parseOrder{
				{place = 1, points = 6}, {place = 1, points = 6}, {place = 3, points = 3}, {place = 3, points = 0},
			})
		end)

		it('does not share a place without a place', function()
			assert.are_same({-1, -2}, StandingTableLegacyGroupSlot.parseOrder{{points = 0}, {points = 0}})
		end)
	end)

	it('maps the short legacy statuses', function()
		assert.are_same(
			{'up', 'stayup', 'stay', 'staydown', 'down', 'down', 'seedup'},
			Array.map({'u', 'su', 's', 'sd', 'd', 'drop', 'seedup'}, StandingTableLegacyGroupSlot.parseStatus)
		)
		assert.is_nil(StandingTableLegacyGroupSlot.parseStatus(''))
	end)

	describe('rendering', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		local Json = require('Module:Json')

		before_each(function()
			TeamTemplateMock.setUp()
			stub(mw.ext.LiquipediaDB, 'lpdb', {})
			stub(mw.ext.LiquipediaDB, 'lpdb_standingstable')
			stub(mw.ext.LiquipediaDB, 'lpdb_standingsentry')
		end)

		after_each(function()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_standingstable:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_standingsentry:revert()
			TeamTemplateMock.tearDown()
		end)

		local function team(name)
			return '<span class="team-template-team-standard" data-highlighting-class="' .. name .. '"></span>'
		end

		local function storedEntries()
			---@diagnostic disable-next-line: undefined-field
			local entries = Array.map(mw.ext.LiquipediaDB.lpdb_standingsentry.calls, function(call)
				return call.vals[2]
			end)
			return Array.sortBy(entries, function(entry) return entry.slotindex end)
		end

		it('renders the slots in their order with their statuses', function()
			StandingTableLegacyGroupSlot.slotStart{'Group A', width = '400px'}
			StandingTableLegacyGroupSlot.slot{team('Team Liquid'), place = '1', win_m = '1', lose_m = '2', pbg = 'u', bg = 'u'}
			StandingTableLegacyGroupSlot.slot{team('mouz'), place = '2', win_m = '2', lose_m = '1', pbg = 'd'}
			StandingTableLegacyGroupSlot.slot{team('heroic'), place = 'dq', win_m = '3', lose_m = '0'}
			local html = tostring(StandingTableLegacyGroupSlot.templateEnd())
			assert.is_truthy(html:find('Group A', 1, true))

			local entries = storedEntries()
			assert.are_same(
				{'team liquid', 'mouz', 'heroic'},
				Array.map(entries, function(entry) return entry.opponentname:lower() end)
			)
			assert.are_same({'up', 'down', 'dq'}, Array.map(entries, function(entry) return entry.definitestatus end))
			assert.are_same({3, 6}, {Json.parse(entries[1].scoreboard).points, Json.parse(entries[2].scoreboard).points})
		end)

		it('shares the placement of rows sharing their place', function()
			StandingTableLegacyGroupSlot.slotStart{'Group B'}
			StandingTableLegacyGroupSlot.slot{team('Team Liquid'), place = '1', win_m = '2'}
			StandingTableLegacyGroupSlot.slot{team('mouz'), place = '1', win_m = '2'}
			StandingTableLegacyGroupSlot.slot{team('heroic'), place = '3', win_m = '0'}
			StandingTableLegacyGroupSlot.templateEnd()
			assert.are_same({1, 1, 3}, Array.map(storedEntries(), function(entry) return entry.placement end))
		end)

		it('errors on slots without a start', function()
			StandingTableLegacyGroupSlot.slot{team('mouz'), place = '1'}
			assert.error(function() StandingTableLegacyGroupSlot.templateEnd() end)
		end)
	end)
end)
