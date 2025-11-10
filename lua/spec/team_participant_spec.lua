--- Triple Comment to Enable our LLS Plugin
insulate('Team Participant', function()
	it('integration tests', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()
		local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)

		local TeamParticipantsController = require('Module:TeamParticipants/Controller')

		GoldenTest('team_participant', tostring(TeamParticipantsController.fromTemplate{
			{
				'Team Liquid',
				qualifyingPage = 'TripleVCT/2025/Game Changers/North America/Stage 2',
				players = {
					{'alexis'},
					{'dodonut'},
					{'meL'},
					{'Noia'},
					{'sarah'},
					{'effys', role = 'Head Coach'},
					{'Veer', role = 'Coach'},
				},
				notes = {
					{'SOME TEXT HERE'},
				}
			},
			{
				'bds',
				qualifyingPage = 'TripleVCT/2025/Game Changers/North America/Stage 2',
				players = {
					{'EletricBoy'},
					{'hjpalpha'},
					{'Eetu'},
					{'Syntactic Sugar'},
					{'Syntactic Salt'},
					{'Rathoz', role = 'Coach'},
				},
				notes = {
					{'Best Team in the World!', highlighted = true},
				}
			},
		}))

		LpdbQuery:revert()
		TeamTemplateMock.tearDown()
	end)
end)
