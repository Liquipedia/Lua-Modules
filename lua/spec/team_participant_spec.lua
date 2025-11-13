--- Triple Comment to Enable our LLS Plugin
insulate('Team Participant', function()
	it('integration tests', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()
		local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
		local LpdbPlacementStore = stub(mw.ext.LiquipediaDB, 'lpdb_placement', function() end)

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
					{'effys', role = 'Head Coach', type = 'staff'},
					{'Veer', role = 'Coach', type = 'staff'},
				},
				notes = {
					{'SOME TEXT HERE'},
				}
			},
			{
				'bds',
				qualifyingPage = 'TripleVCT/2025/Game Changers/North America/Stage 2',
				players = {
					{'ElectricalBoy'},
					{'hjpalpha'},
					{'Eetu'},
					{'SyntacticSugar'},
					{'SyntacticSalt'},
					{'Rathoz', role = 'Coach', type = 'staff'},
				},
				notes = {
					{'Best Team in the World!', highlighted = true},
				}
			},
		}))

		LpdbQuery:revert()
		LpdbPlacementStore:revert()
		TeamTemplateMock.tearDown()
	end)
end)
