--- Triple Comment to Enable our LLS Plugin
insulate('Team Participant', function()
	it('integration tests', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()
		local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
		local LpdbPlacementStore = stub(mw.ext.LiquipediaDB, 'lpdb_placement', function() end)

		local TeamParticipantsController = require('Module:TeamParticipants/Controller')

		GoldenTest('team_participant', 
			'<script>liquipedia.switchButtons.switchGroups["team-cards-show-rosters"].nodes[0].click()</script>'
			.. tostring(TeamParticipantsController.fromTemplate{
			{
				'Team Liquid',
				players = {
					{'alexis'},
					{'dodonut'},
					{'meL'},
					{'Noia'},
					{'sarah'},
					{'effys', role = 'Head Coach', type = 'staff'},
					{'Veer', role = 'Coach', type = 'staff'},
				},
				qualification = {
					method = 'qual',
					url = 'https://google.com',
					text = 'FooBar',
				},
				notes = {
					{'SOME TEXT HERE'},
				}
			},
			{
				'bds',
				qualification = {
					method = 'invite',
					text = 'Invited',
				},
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
