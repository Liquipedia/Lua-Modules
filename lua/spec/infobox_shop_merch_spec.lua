local ShopMerch = require('Module:Widget/Infobox/ShopMerch')

local function render(args)
	local widget = ShopMerch{args = args}
	local rendered = widget:render()
	return rendered and mw.text.jsonEncode(rendered) or nil
end

describe('Infobox/ShopMerch', function()
	it('renders for valid slugs', function()
		local output = render{shoplink = 'test'}
		assert.is_not_nil(output)
		---@cast output -nil
		assert.is_truthy(output:find('https://links.liquipedia.net/test', 1, true))
	end)

	it('uses default shop url when shoplink=true', function()
		local output = render{shoplink = 'true'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('https://links.liquipedia.net/tlstore', 1, true))
	end)

	it('strips leading slashes from slugs', function()
		local output = render{shoplink = '/test'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('https://links.liquipedia.net/test', 1, true))

		local output2 = render{shoplink = '///test'}
		assert.is_truthy(output2 and output2:find('https://links.liquipedia.net/test', 1, true))
	end)

	it('accepts query parameters and fragments in slugs', function()
		local output1 = render{shoplink = 'test?utm_source=lp'}
		assert.is_truthy(output1 and output1:find('utm_source=lp', 1, true))

		local output2 = render{shoplink = 'test#section'}
		assert.is_truthy(output2 and output2:find('#section', 1, true))
	end)

	it('rejects inputs that look like full URLs or protocols', function()
		assert.has_error(function() render{shoplink = 'https://links.liquipedia.net/test'} end)
		assert.has_error(function() render{shoplink = 'http://example.com'} end)
		assert.has_error(function() render{shoplink = '//links.liquipedia.net/test'} end)
		assert.has_error(function() render{shoplink = 'ftp://test'} end)
		assert.has_error(function() render{shoplink = 'links.liquipedia.net/test'} end)
	end)

	it('rejects inputs with format-breaking characters', function()
		assert.has_error(function() render{shoplink = 'te st'} end)
		assert.has_error(function() render{shoplink = '<test>'} end)
		assert.has_error(function() render{shoplink = 'test>'} end)
		assert.has_error(function() render{shoplink = '[test]'} end)
		assert.has_error(function() render{shoplink = '"test"'} end)
	end)

	it('rejects URLs exceeding MAX_URL_LENGTH', function()
		local long_slug = string.rep('a', 2001)
		assert.has_error(function() render{shoplink = long_slug} end)
	end)
end)
