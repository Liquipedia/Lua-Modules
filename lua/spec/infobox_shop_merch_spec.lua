local ShopMerch = require('Module:Widget/Infobox/ShopMerch')

local function render(args)
	local widget = ShopMerch{args = args}
	local rendered = widget:render()
	return rendered and mw.text.jsonEncode(rendered) or nil
end

describe('Infobox/ShopMerch', function()
	local original_mw_uri

	before_each(function()
		original_mw_uri = mw.uri
		mw.uri = {
			new = function(str)
				return setmetatable({}, {
					__tostring = function()
						-- Simple mock encoding for common non-ASCII chars to test length expansion
						return str:gsub('ö', '%%C3%%B6')
					end
				})
			end
		}
	end)

	after_each(function()
		mw.uri = original_mw_uri
	end)

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

	it('handles non-ASCII characters with length expansion', function()
		-- 'ö' is 2 bytes in Lua, but %C3%B6 is 6 chars in URL
		local output = render{shoplink = 'töst'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('https://links.liquipedia.net/t%C3%B6st', 1, true))
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

	it('rejects URLs exceeding MAX_URL_LENGTH after encoding', function()
		-- 1973 'a's + prefix (27) = 2000. 1974 'a's = 2001.
		local long_slug = string.rep('a', 1974)
		assert.has_error(function() render{shoplink = long_slug} end)

		-- Testing length expansion: 500 'ö's is 1000 bytes, but 3000 encoded chars
		local expanding_slug = string.rep('ö', 500)
		assert.has_error(function() render{shoplink = expanding_slug} end)
	end)
end)