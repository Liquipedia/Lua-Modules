---
-- @Liquipedia
-- page=Module:Infobox/Campaign
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Header = Widgets.Header
local Center = Widgets.Center

---@class CampaignInfobox: BasicInfobox
local Campaign = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Campaign.run(frame)
	local campaign = Campaign(frame)
	return campaign:createInfobox()
end

---@return string
function Campaign:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = self.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
	}

	self:categories('Campaign')

	return self:build(widgets)
end


return Campaign
