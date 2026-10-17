--- Triple Comment to Enable our LLS Plugin
-- Display layer of Module:Features/MapTable: content asserts and a golden snapshot

describe('MapTable Display', function()
	local MapTableDisplay

	setup(function()
		SetActiveWiki('trackmania')
		MapTableDisplay = require('Module:Features/MapTable/Components/Display')
	end)

	teardown(function()
		SetActiveWiki()
	end)

	it('renders the header, the map, the mapper and the links', function()
		local html = tostring(MapTableDisplay{
			rows = {{map = 'Stadium'}},
			mappers = {{
				{index = 1, displayName = 'Player One', pageName = 'Player One', flag = 'de'},
				{index = 2, displayName = 'Player Two', pageName = 'Player Two', flag = 'cn'},
			}},
			links = {{twitch = 'https://www.twitch.tv/channel'}},
		})

		assert.is_truthy(html:find('Author', 1, true))
		assert.is_truthy(html:find('Map', 1, true))
		assert.is_truthy(html:find('Links', 1, true))
		assert.is_truthy(html:find('Stadium', 1, true))
		assert.is_truthy(html:find('[[Player One|Player One]]', 1, true))
		assert.is_truthy(html:find('[[File:de_hd.png|36x24px|Germany|link=]]', 1, true))
		assert.is_truthy(html:find('[[Player Two|Player Two]]', 1, true))
		assert.is_truthy(html:find('[[File:cn_hd.png|36x24px|China|link=]]', 1, true))
		assert.is_truthy(html:find('[https://www.twitch.tv/channel ', 1, true))
		assert.is_truthy(html:find('lp-icon lp-twitch lp-icon-25', 1, true))
	end)

	it('renders a row without a mapper or a link', function()
		local html = tostring(MapTableDisplay{
			rows = {{map = 'Coast'}},
			mappers = {{}},
			links = {{}},
		})

		assert.is_truthy(html:find('Coast', 1, true))
		assert.is_nil(html:find('inline-player', 1, true))
		assert.is_nil(html:find('[[File:', 1, true))
		assert.is_nil(html:find('lp-icon', 1, true))
	end)

	it('renders the map as a snapshot', function()
		GoldenTest('maptable_display', tostring(MapTableDisplay{
			rows = {{map = 'Stadium'}},
			mappers = {{
				{index = 1, displayName = 'Player One', pageName = 'Player One', flag = 'de'},
				{index = 2, displayName = 'Player Two', pageName = 'Player Two', flag = 'cn'},
			}},
			links = {
				{
					twitch = 'https://www.twitch.tv/channel',
				},
			},
		}))
	end)
end)
