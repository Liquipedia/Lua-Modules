---
-- @Liquipedia
-- page=Module:Infobox/Campaign
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Widget/All')
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
