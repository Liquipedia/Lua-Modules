--- Triple Comment to Enable our LLS Plugin
local VodLink = require('Module:VodLink')

describe('VodLink.display', function()
	it('should return NoVod icon when novod is true', function()
		local args = {novod = true}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Help Liquipedia find this VOD">' ..
			'[[File:NoVod.png|32px|link=]]</span>',
			result
		)
	end)

	it('should return Game icon when gamenum is less than or equal to 11', function()
		local args = {vod = 'somevod', gamenum = 5}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch Game 5">' ..
			'[[File:VOD Icon5.png|32px|link=somevod]]</span>',
			result
		)
	end)

	it('should return default VOD icon when gamenum is greater than 11', function()
		local args = {vod = 'somevod', gamenum = 12}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch Game 12">' ..
			'[[File:VOD Icon.png|32px|link=somevod]]</span>',
			result
		)
	end)

	it('should return tlpd link when source is tlpd', function()
		local args = {vod = '12345', source = 'tlpd'}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch VOD">' ..
			'[[File:VOD Icon.png|32px|link=https://www.tl.net/tlpd/sc2-korean/games/12345/vod]]</span>',
			result
		)
	end)

	it('should return tlpd-kr link when source is tlpd-kr', function()
		local args = {vod = '12345', source = 'tlpd-kr'}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch VOD">' ..
			'[[File:VOD Icon.png|32px|link=https://www.tl.net/tlpd/sc2-korean/games/12345/vod]]</span>',
			result
		)
	end)

	it('should return tlpd-int link when source is tlpd-int', function()
		local args = {vod = '12345', source = 'tlpd-int'}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch VOD">' ..
			'[[File:VOD Icon.png|32px|link=https://www.tl.net/tlpd/sc2-international/games/12345/vod]]</span>',
			result
		)
	end)

	it('should use htext when provided', function()
		local args = {vod = 'somevod', htext = 'Custom Title'}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Custom Title">' ..
			'[[File:VOD Icon.png|32px|link=somevod]]</span>',
			result
		)
	end)

	it('should return default VOD icon when no special conditions are met', function()
		local args = {vod = 'somevod'}
		local result = tostring(VodLink.display(args))
		assert.are.equal(
			'<span class="plainlinks vodlink" title="Watch VOD">' ..
			'[[File:VOD Icon.png|32px|link=somevod]]</span>',
			result
		)
	end)
end)
