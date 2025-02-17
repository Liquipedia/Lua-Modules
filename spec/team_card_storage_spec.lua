--- Triple Comment to Enable our LLS Plugin
describe('Team Card Storage', function()
	local TCStorage = require('Module:TeamCard/Storage')
	local InfoboxLeague = require('Module:Infobox/League/Custom')

	it('standard fields', function()
		local stubLpdb = stub(mw.ext.LiquipediaDB, "lpdb", {})
		local stubLpdbTournament = stub(mw.ext.LiquipediaDB, "lpdb_tournament")

		local tournamentDatas = require('test_assets.tournaments')
		local tournamentData = tournamentDatas.dummy
		InfoboxLeague.run(tournamentData)

		local args = {image1 = 'dummy.png', imagedark1 = 'dummydark.png'}
		local actualData = TCStorage._addStandardLpdbFields({}, 'Team Liquid', args, 'prefix')

		local expectedData = {
			objectName = 'ranking_prefix_team liquid',
			tournament = tournamentData.name,
			series = tournamentData.series,
			parent = 'FakePage',
			startdate = tournamentData.sdate,
			date = tournamentData.edate,
			image = args.image1,
			imagedark = args.imagedark1,
			mode = 'team',
			participant = 'Team Liquid',
			icon = tournamentData.icon,
			icondark = tournamentData.icondark,
			game = string.lower(tournamentData.game),
			liquipediatier = tournamentData.liquipediatier,
			liquipediatiertype = tournamentData.liquipediatiertype,
			extradata = {}
		}
		assert.are_same(expectedData, actualData)
		stubLpdb:revert()
		stubLpdbTournament:revert()
	end)

	it('object name', function()
		assert.are_equal('ranking_foo_örban', TCStorage._getLpdbObjectName('Örban', 'foo'))
		assert.are_equal('participant_tbd_1', TCStorage._getLpdbObjectName('TBD'))
		assert.are_equal('participant_tbd_2', TCStorage._getLpdbObjectName('TBD'))
	end)

	describe('qualifier parsing', function()
		it('raw text', function()
			local test = 'Foo Bar'
			local text, internal, external = TCStorage._parseQualifier(test)
			assert.are_equal('Foo Bar', text)
			assert.is_nil(internal)
			assert.is_nil(external)
		end)

		it('SimpleInternalLink', function()
			local test = '[[Foo_Bar/2022|Foo Bar]]'
			local text, internal, external = TCStorage._parseQualifier(test)
			assert.are_equal('Foo Bar', text)
			assert.are_equal('Foo_Bar/2022', internal)
			assert.is_nil(external)
		end)

		it('RelativeInternalLink', function()
			local test = '[[/2022|Foo Bar]]'
			local text, internal, external = TCStorage._parseQualifier(test)
			assert.are_equal('Foo Bar', text)
			assert.are_equal('FakePage/2022', internal)
			assert.is_nil(external)
		end)

		it('FixingSpaceInternalLink', function()
			local test = '[[Foo Bar/2022|Foo Bar]]'
			local text, internal, external = TCStorage._parseQualifier(test)
			assert.are_equal('Foo Bar', text)
			assert.are_equal('Foo_Bar/2022', internal)
			assert.is_nil(external)
		end)

		it('ExternalLink', function()
			local test = '[https://foo.bar Foo Bar]'
			local text, internal, external = TCStorage._parseQualifier(test)
			assert.are_equal('Foo Bar', text)
			assert.is_nil(internal)
			assert.are_equal('https://foo.bar', external)
		end)

		it('ExternalLinkNoSpace', function()
			local test = '[https://foo.bar]'
			local text, internal, external = TCStorage._parseQualifier(test)
			assert.are_equal('', text)
			assert.is_nil(internal)
			assert.are_equal('https://foo.bar', external)
		end)
	end)
end)
