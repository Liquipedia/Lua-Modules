---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Website
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})
local Links = Lua.import('Module:Links', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Cell = Widgets.Cell
local Center = Widgets.Center
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable

local Website = Class.new(BasicInfobox)

function Website.run(frame)
	local website = Website(frame)
	return website:createInfobox()
end

function Website:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'Website Information'},
		Cell{name = 'Type', content = {args.type}},
		Cell{name = 'Available Language(s)', content = self:getAllArgsForBase(args, 'language')},
		Cell{name = 'Content License', content = {args.content_license}},
		Cell{name = 'Launched', content = {args.date_of_launch}},
		Cell{name = 'Current Status', content = {args.current_status}},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				local links = Links.transform(args)
				if not Table.isEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links}
					}
				end
			end
		},
		Center{content = {args.footnotes}},
	}

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

return Website
