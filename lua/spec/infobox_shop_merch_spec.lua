local ShopMerch = require('Module:Widget/Infobox/ShopMerch')

local function render(args)
	local widget = ShopMerch{args = args}
	local rendered = widget:render()
	return rendered and mw.text.jsonEncode(rendered) or nil
end

describe('Infobox/ShopMerch', function()
	local original_mw_uri

	-- mw.uri is not available in the standalone Lua test environment.
	-- We mock it here to simulate URL parsing and validation logic.
	local function get_mock_uri()
		local mock = {}

		function mock.new(str)
			if not str then return nil end

			local uri = {}
			uri._raw = str

			local protocol, rest = str:match("^([a-zA-Z]+)://(.+)$")
			if protocol then
				uri.protocol = protocol:lower()

				local pathStart = rest:find("[/?#]")
				if pathStart then
					uri.host = rest:sub(1, pathStart - 1):lower()
					uri.pathString = rest:sub(pathStart)
				else
					uri.host = rest:lower()
					uri.pathString = ""
				end
			end

			-- Mimic MW: tostring reconstructs and normalizes
			return setmetatable(uri, {
				__tostring = function(self)
					if not self.protocol or not self.host then return str end
					return self.protocol .. "://" .. self.host:lower() .. self.pathString
				end
			})
		end

		function mock.validate(uri)
			if not uri or not uri.protocol or not uri.host then return false end
			-- Mimic MW validation: Check for illegal characters in the RAW string
			if uri._raw:find("[ <>\"`%[%]]") then return false end
			return true
		end

		return mock
	end

	before_each(function()
		original_mw_uri = mw.uri
		mw.uri = get_mock_uri()
	end)

	after_each(function()
		mw.uri = original_mw_uri
	end)

	it('renders for valid https links.liquipedia.net URLs', function()
		local output = render{shoplink = 'https://links.liquipedia.net/test'}
		assert.is_not_nil(output)
		---@cast output -nil
		assert.is_truthy(output:find('https://links.liquipedia.net/test', 1, true))
	end)

	it('uses default shop url when shoplink=true', function()
		local output = render{shoplink = 'true'}
		assert.is_not_nil(output)
		assert.is_truthy(output:find('https://links.liquipedia.net/tlstore', 1, true))
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

	it('accepts query parameters and fragments (even without slash)', function()
		local output1 = render{shoplink = 'https://links.liquipedia.net/test?utm_source=lp'}
		assert.is_truthy(output1 and output1:find('utm_source=lp', 1, true))

		local output2 = render{shoplink = 'https://links.liquipedia.net?q=1'}
		assert.is_truthy(output2 and output2:find('?q=1', 1, true))
	end)

	it('normalizes uppercase hosts', function()
		-- Validates that the module is returning the normalized URI object, not the raw string
		local output = render{shoplink = 'https://LINKS.LIQUIPEDIA.NET/test'}
		assert.is_not_nil(output)
		---@cast output -nil
		assert.is_truthy(output:find('https://links.liquipedia.net/test', 1, true))
	end)

	it('rejects inputs with format-breaking characters', function()
		assert.is_nil(render{shoplink = 'https://links.liquipedia.net/te st'})
		assert.is_nil(render{shoplink = 'https://links.liquipedia.net/<test>'})
		assert.is_nil(render{shoplink = 'https://links.liquipedia.net/test>'})
		assert.is_nil(render{shoplink = '[https://links.liquipedia.net/test]'})
	end)

	it('rejects URLs exceeding MAX_URL_LENGTH', function()
		local long_url = 'https://links.liquipedia.net/' .. string.rep('a', 2001)
		assert.is_nil(render{shoplink = long_url})
	end)
end)
