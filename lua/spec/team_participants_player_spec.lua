--- Triple Comment to Enable our LLS Plugin
describe('TeamParticipants player parsing', function()
	local TeamParticipantsWikiParser

	before_each(function()
		TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
	end)

	describe('parsePlayer status', function()
		it('passes status through from input', function()
			local player = TeamParticipantsWikiParser.parsePlayer({'s1mple', status = 'former'})
			assert.are_equal('former', player.extradata.status)
		end)

		it('passes status through independent of type', function()
			local player = TeamParticipantsWikiParser.parsePlayer({'s1mple', type = 'sub', status = 'inactive'})
			assert.are_equal('inactive', player.extradata.status)
		end)

		it('status is nil when not provided', function()
			local player = TeamParticipantsWikiParser.parsePlayer({'s1mple'})
			assert.is_nil(player.extradata.status)
		end)
	end)
end)
