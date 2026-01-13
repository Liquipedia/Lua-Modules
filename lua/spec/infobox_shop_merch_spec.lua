--- Triple Comment to Enable our LLS Plugin
local ShopMerch = require('Module:Widget/Infobox/ShopMerch')

local function render(args)
	local widget = ShopMerch{args = args}
	local rendered = widget:render()
	return rendered and mw.text.jsonEncode(rendered) or nil
end

describe('Infobox/ShopMerch', function()
	it('renders for valid https links.liquipedia.net URLs', function()
		local output = render{shoplink = 'https://links.liquipedia.net/test'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('https://links.liquipedia.net/test', 1, true))
	end)

	it('uses default shop url when shoplink=true', function()
		local output = render{shoplink = 'true'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('https://links.liquipedia.net/', 1, true))
	end)

	it('normalizes schemeless links.liquipedia.net URLs to https', function()
		local output = render{shoplink = 'links.liquipedia.net/test'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('https://links.liquipedia.net/test', 1, true))
	end)

	it('rejects non-https URLs', function()
		assert.is_nil(render{shoplink = 'http://links.liquipedia.net/test'})
	end)

	it('rejects non-allowed hosts', function()
		assert.is_nil(render{shoplink = 'https://example.com/test'})
	end)

	it('accepts query parameters (e.g. UTM) and fragments', function()
		local output = render{shoplink = 'https://links.liquipedia.net/test?utm_source=lp&utm_medium=infobox#top'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('utm_source=lp', 1, true))
	end)

	it('allows customizing text and icon via separate args', function()
		local output = render{
			shoplink = 'https://links.liquipedia.net/test',
			shoptext = 'My Shop Button',
			shopicon = 'shopping_bag',
		}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('My Shop Button', 1, true))
	end)

	it('rejects inputs with format-breaking characters', function()
		assert.is_nil(render{shoplink = 'https://links.liquipedia.net/te st'})
		assert.is_nil(render{shoplink = 'https://links.liquipedia.net/<test>'})
		assert.is_nil(render{shoplink = 'https://links.liquipedia.net/test>'})
		assert.is_nil(render{shoplink = '[https://links.liquipedia.net/test]'})
		assert.is_nil(render{shoplink = 'https://links.liquipedia.net/test"'})
		assert.is_nil(render{shoplink = 'https://links.liquipedia.net/test`'})
	end)

	it('uses default text when not customized', function()
		local output = render{shoplink = 'https://links.liquipedia.net/test'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('Shop in the Liquipedia Store', 1, true))
	end)

	it('falls back to defaults when values empty', function()
		local output = render{shoplink = 'https://links.liquipedia.net/test', shoptext = '', shopicon = ''}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('Shop in the Liquipedia Store', 1, true))
	end)
end)
