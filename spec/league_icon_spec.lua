--- Triple Comment to Enable our LLS Plugin
local LeagueIcon = require('Module:LeagueIcon')

local FILLER_EXPECT = '<span class="league-icon-small-image">[[File:Logo filler event.png|link=]]</span>'
local ICON_DARK_EXPECT = '<span class="league-icon-small-image">[[File:DarkIcon.png|link=||50x50px]]</span>'

local ICON_BOTH_EXPECT =
	'<span class="league-icon-small-image lightmode">[[File:LightIcon.png|link=||50x50px]]</span>' ..
	'<span class="league-icon-small-image darkmode">[[File:DarkIcon.png|link=||50x50px]]</span>'
local ICON_WITH_LINK_EXPECT = '<span class="league-icon-small-image">[[File:Icon.png|link=link|name|50x50px]]</span>'
local ICON_WITH_LINK_BOTH_EXPECT =
	'<span class="league-icon-small-image lightmode">[[File:LightIcon.png|link=link|name|50x50px]]</span>' ..
	'<span class="league-icon-small-image darkmode">[[File:DarkIcon.png|link=link|name|50x50px]]</span>'

insulate('LeagueIcon.display', function()
	it('should return filler icon when no icons are provided', function()
		local args = {}
		local result = LeagueIcon.display(args)
		assert.are.equal(FILLER_EXPECT, result)
	end)

	it('should return iconDark when only iconDark is provided', function()
		local args = {iconDark = 'DarkIcon.png'}
		local result = LeagueIcon.display(args)
		assert.are.equal(ICON_DARK_EXPECT .. '[[Category:Pages with only icondark]]', result)
	end)

	it('should return both icons when both icon and iconDark are provided', function()
		local args = {icon = 'LightIcon.png', iconDark = 'DarkIcon.png'}
		local result = LeagueIcon.display(args)
		assert.are.equal(ICON_BOTH_EXPECT, result)
	end)

	it('should not use template when noTemplate option is true', function()
		local args = {options = {noTemplate = true}}
		local result = LeagueIcon.display(args)
		assert.are.equal(FILLER_EXPECT, result)
	end)

	it('should not include link when noLink option is true', function()
		local args = {icon = 'LightIcon.png', iconDark = 'DarkIcon.png', options = {noLink = true}}
		local result = LeagueIcon.display(args)
		assert.are.equal(ICON_BOTH_EXPECT, result)
	end)
end)

insulate('LeagueIcon._make', function()
	it('should return single icon when icon and iconDark are identical', function()
		local result = LeagueIcon._make('Icon.png', 'Icon.png', 'link', 'name', 50)
		assert.are.equal(ICON_WITH_LINK_EXPECT, result)
	end)

	it('should return both icons when icon and iconDark are different', function()
		local result = LeagueIcon._make('LightIcon.png', 'DarkIcon.png', 'link', 'name', 50)
		assert.are.equal(ICON_WITH_LINK_BOTH_EXPECT, result)
	end)
end)

insulate('LeagueIcon.getIconFromTemplate', function()
	it('should return empty icons when no template string is provided', function()
		local icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate({})
		assert.are.equal('', icon)
		assert.are.equal('', iconDark)
		assert.are.equal('', trackingCategory)
	end)

	it('should extract icons from template string', function()
		local templateString = 'File:LightIcon.pngFile:DarkIcon.png'
		local icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate({
			stringOfExpandedTemplate = templateString
		})
		assert.are.equal('LightIcon.png', icon)
		assert.are.equal('DarkIcon.png', iconDark)
		assert.are.equal('', trackingCategory)
	end)
end)

insulate('LeagueIcon.getTemplate', function()
	it('should return nil when no series or abbreviation is provided', function()
		local result = LeagueIcon.getTemplate({})
		assert.are.equal(nil, result)
	end)

	it('should expand template with series', function()
		local frame = mw.getCurrentFrame()
		spy.on(frame, 'expandTemplate')
		--- @diagnostic disable-next-line: duplicate-set-field
		frame.expandTemplate = function() return 'ExpandedTemplate' end
		local result = LeagueIcon.getTemplate({series = 'SomeSeries'})
		assert.are.equal('ExpandedTemplate', result)
	end)

	it('should expand template with abbreviation when series is not found', function()
		local frame = mw.getCurrentFrame()
		spy.on(frame, 'expandTemplate')
		--- @diagnostic disable-next-line: duplicate-set-field
		frame.expandTemplate = function(_, template)
			if template.args[1] == 'Series' then
				return 'false'
			else
				return 'ExpandedTemplate'
			end
		end
		local result = LeagueIcon.getTemplate({abbreviation = 'SomeAbbreviation'})
		assert.are.equal('ExpandedTemplate', result)
	end)
end)

insulate('LeagueIcon.generate', function()
	it('should generate code with valid arguments', function()
		local args = {icon = 'Icon.png', link = 'link', name = 'name', series = 'series'}
		GoldenTest('LeagueIcon.generate_copy_paste_gen', LeagueIcon.generate(args))
	end)

	it('should throw error when no link or series is provided', function()
		local args = {icon = 'Icon.png'}
		assert.has_error(function() LeagueIcon.generate(args) end, 'No series/link specified')
	end)
end)
