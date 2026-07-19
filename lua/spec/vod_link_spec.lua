--- Triple Comment to Enable our LLS Plugin
local VodLink = require('Module:VodLink')

describe('VodLink.display', function()
	it('should return Game icon when gamenum is less than or equal to 11', function()
		local args = {vod = 'somevod', gamenum = 5}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch Game 5">' ..
			'[[File:Vod-5.svg|32px|link=somevod]]</span>',
			result
		)
	end)

	it('should return default VOD icon when gamenum is greater than 9', function()
		local args = {vod = 'somevod', gamenum = 10}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch Game 10">' ..
			'[[File:Vod.svg|32px|link=somevod]]</span>',
			result
		)
	end)

	it('should return default VOD icon when no special conditions are met', function()
		local args = {vod = 'somevod'}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch VOD">' ..
			'[[File:Vod.svg|32px|link=somevod]]</span>',
			result
		)
	end)
end)
