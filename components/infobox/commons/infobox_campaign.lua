---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Campaign
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Header = Widgets.Header
local Center = Widgets.Center

local Campaign = Class.new(BasicInfobox)

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
