--- Triple Comment to Enable our LLS Plugin
describe('Standings participant widget', function()
	local Participant = require('Module:Widget/Standings/Participant')

	local SOLO = {type = 'solo', players = {{pageName = 'Alpha', displayName = 'Alpha'}}}
	local TEAM = {type = 'team', template = 'team liquid'}

	it('renders the plain opponent when not disqualified', function()
		local html = tostring(Participant{opponent = SOLO})
		assert.is_falsy(html:find('standings-participant', 1, true))
		assert.is_falsy(html:find('</s>', 1, true))
		assert.is_falsy(html:find('>DQ<', 1, true))
	end)

	it('strikes through a disqualified player and adds the DQ label', function()
		local html = tostring(Participant{opponent = SOLO, disqualified = true})
		assert.is_truthy(html:find('class="standings-participant"', 1, true))
		assert.is_truthy(html:find('</s>', 1, true))
		assert.is_truthy(html:find('data%-placement%-type="dq">DQ</div></div>$'))
	end)

	it('strikes through a disqualified team and adds the DQ label', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
		TeamTemplateMock.setUp()
		local html = tostring(Participant{opponent = TEAM, disqualified = true})
		TeamTemplateMock.tearDown()
		assert.is_truthy(html:find('</s>', 1, true))
		assert.is_truthy(html:find('data%-placement%-type="dq">DQ</div></div>$'))
	end)
end)
