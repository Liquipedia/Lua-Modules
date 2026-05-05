--- Triple Comment to Enable our LLS Plugin
describe('Team Participant Player Number', function()
	local TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')

	it('parses number string as integer', function()
		local player = TeamParticipantsWikiParser.parsePlayer{'PlayerName', number = '5'}
		assert.are_equal(5, player.extradata.number)
	end)

	it('parses number passed as a Lua number', function()
		local player = TeamParticipantsWikiParser.parsePlayer{'PlayerName', number = 7}
		assert.are_equal(7, player.extradata.number)
	end)

	it('returns nil when number is absent', function()
		local player = TeamParticipantsWikiParser.parsePlayer{'PlayerName'}
		assert.is_nil(player.extradata.number)
	end)

	it('returns nil for non-numeric number input', function()
		local player = TeamParticipantsWikiParser.parsePlayer{'PlayerName', number = 'abc'}
		assert.is_nil(player.extradata.number)
	end)
end)
