---
-- @Liquipedia
-- page=Module:Infobox/Website
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Links = Lua.import('Module:Links')

local Widgets = Lua.import('Module:Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Cell = Widgets.Cell
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class WebsiteInfobox: BasicInfobox
---@operator call(Frame): WebsiteInfobox
local Website = Class.new(BasicInfobox)

---@param frame Frame
---@return Widget
function Website.run(frame)
	local website = Website(frame)
	return website:createInfobox()
end

---@return Widget
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
		Cell{name = 'Type', children = {args.type}},
		Cell{name = 'Available Language(s)', children = self:getAllArgsForBase(args, 'language')},
		Cell{name = 'Content License', children = {args.content_license}},
		Cell{name = 'Launched', children = {args.date_of_launch}},
		Cell{name = 'Current Status', children = {args.current_status}},
		Customizable{id = 'custom', children = {}},
		Widgets.Links{links = Links.transform(args)},
		Center{children = {args.footnotes}},
	}

	return self:build(widgets, 'Website')
end

return Website
