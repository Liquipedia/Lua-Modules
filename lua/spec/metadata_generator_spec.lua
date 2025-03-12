--- Triple Comment to Enable our LLS Plugin
describe('metadata generator', function()
	SetActiveWiki('counterstrike')
	local MetadataGenerator = require('wikis.commons.MetadataGenerator')

	teardown(function ()
		SetActiveWiki('')
	end)

	it('generate', function()
		local EXPECTED_RESULT =
				'Intel Extreme Masters XVI - Cologne is an offline German CS:GO tournament organized by ESL.' ..
				' This S-Tier tournament took place from Jul 06 to 18 2021 featuring 24 teams competing' ..
				' over a total prize pool of $1,000,000 USD.'

		assert.are_same(EXPECTED_RESULT, MetadataGenerator.tournament({
			name = 'Intel Extreme Masters XVI - Cologne',
			tickername = 'IEM Cologne 2021',
			organizer = 'ESL',
			type = 'Offline',
			prizepoolusd = '1,000,000',
			liquipediatier = '1',
			sdate = '2021-07-06',
			edate = '2021-07-18',
			country = 'Germany',
			game = 'csgo',
			team_number = '24',
		}))
	end)
end)
