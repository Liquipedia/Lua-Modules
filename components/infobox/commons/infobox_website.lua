---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Website
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local BasicInfobox = require('Module:Infobox/Basic')
local Links = require('Module:Links')
local Table = require('Module:Table')

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
		Cell{name = 'Available language(s)', content = self:getAllArgsForBase(args, 'language')},
		Cell{name = 'Content license', content = {args.content_license}},
		Cell{name = 'Launched', content = {args.date_of_launch}},
		Cell{name = 'Current status', content = {args.current_status}},
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
