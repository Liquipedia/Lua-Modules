--- Triple Comment to Enable our LLS Plugin
insulate('Team Participant', function()
	it('integration tests', function()
		local Array = require('Module:Array')
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()

		local LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function(tbl)
			if tbl == 'placement' then
				return Array.filter(require('test_assets/lpdb_placement'), function (asset)
					return asset.pagename == 'Six_Lounge_Series/4/Online_Stage'
				end)
			end
			return {}
		end)
		local TeamParticipantCardGroup = require('Module:Widget/Participants/Team/CardsGroup')

		GoldenTest('team_participant', tostring(TeamParticipantCardGroup{pageName = 'Six_Lounge_Series/4/Online_Stage'}))

		LpdbQuery:revert()
		TeamTemplateMock.tearDown()
	end)
end)
