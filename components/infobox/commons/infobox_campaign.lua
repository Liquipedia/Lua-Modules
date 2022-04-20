---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Campaign
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local InfoboxBasic = require('Module:Infobox/Basic')

local Widgets = require('Module:Infobox/Widget/All')
local Header = Widgets.Header
local Center = Widgets.Center

local Campaign = Class.new(InfoboxBasic)

function Campaign.run(frame)
	local campaign = Campaign(frame)
	return campaign:createInfobox()
end

function Campaign:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = self.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
	}

	infobox:categories('Campaign')

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end


return Campaign
