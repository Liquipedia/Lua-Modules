--- Triple Comment to Enable our LLS Plugin
describe('Team Card Storage', function()
	local TCStorage = require('Module:TeamCard/Storage')
	local InfoboxLeague = require('Module:Infobox/League/Custom')

	it('standard fields', function()
		local tournamentDatas = require('test_assets.tournaments')
		local tournamentData = tournamentDatas.dummy
		InfoboxLeague.run(tournamentData)

		local args = {image1 = 'dummy.png', imagedark1 = 'dummydark.png'}
		local actualData = TCStorage._addStandardLpdbFields({}, 'Team Liquid', args, 'prefix')

		local expectedData = {
			tournament = tournamentData.name,
			series = tournamentData.series,
			parent = 'Module_talk:TeamCard/Storage/testcases',
			startdate = tournamentData.sdate,
			date = tournamentData.edate,
			image = args.image1,
			imagedark = args.imagedark1,
			mode = 'team',
			publishertier = nil,
			icon = tournamentData.icon,
			icondark = tournamentData.icondark,
			game = string.lower(tournamentData.game),
			liquipediatier = tournamentData.liquipediatier,
			liquipediatiertype = tournamentData.liquipediatiertype,
		}
		assert.are_same(expectedData, actualData)
	end)

	it('object name', function()
		assert.are_equal('ranking_foo_örban', TCStorage._getLpdbObjectName('Örban', 'foo'))
		assert.are_equal('participant_tbd_1', TCStorage._getLpdbObjectName('TBD'))
		assert.are_equal('participant_tbd_2', TCStorage._getLpdbObjectName('TBD'))
	end)
end)
