--- Triple Comment to Enable our LLS Plugin
describe('PlayerDisplay link marking', function()
	local PlayerDisplay = require('Module:Player/Display')

	it('BlockPlayer marks a linked player', function()
		local html = tostring(PlayerDisplay.BlockPlayer{
			player = { pageName = 'Some Player', displayName = 'SomeGuy' },
			showFlag = false,
			showFaction = false,
		})
		assert.is_truthy(html:find('link-preview', 1, true))
		assert.is_truthy(html:find('data-preview-page="Some_Player"', 1, true))
	end)

	it('InlinePlayer marks a linked player', function()
		local html = tostring(PlayerDisplay.InlinePlayer{
			player = { pageName = 'Some Player', displayName = 'SomeGuy' },
			showFlag = false,
			showFaction = false,
		})
		assert.is_truthy(html:find('data-preview-page="Some_Player"', 1, true))
	end)
end)
