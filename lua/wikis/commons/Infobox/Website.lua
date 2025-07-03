---
-- @Liquipedia
-- page=Module:Infobox/Website
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Links = Lua.import('Module:Links')

local Widgets = Lua.import('Module:Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Cell = Widgets.Cell
local Center = Widgets.Center
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable

---@class WebsiteInfobox: BasicInfobox
local Website = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Website.run(frame)
	local website = Website(frame)
	return website:createInfobox()
end

---@return string
function Website:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Website Information'},
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
						Title{children = 'Links'},
						Widgets.Links{links = links}
					}
				end
			end
		},
		Center{children = {args.footnotes}},
	}

	return self:build(widgets)
end

return Website
