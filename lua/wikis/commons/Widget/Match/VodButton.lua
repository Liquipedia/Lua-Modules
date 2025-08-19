---
-- @Liquipedia
-- page=Module:Widget/Match/VodButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local VodLink = Lua.import('Module:VodLink')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')
local ImageIcon = Lua.import('Module:Widget/Image/Icon/Image')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class VodButton: Widget
---@operator call(table): VodButton
local VodButton = Class.new(Widget)

---@return Widget?
function VodButton:render()
	local vod = self.props.vods
	local showText = self.props.showText
	if not vod then
		return
	end

	local useDropdownVariant = self.props.variant == 'dropdown'
	local gameNumber = vod.number

	return Button{
		linktype = 'external',
		title = VodLink.getTitle(gameNumber),
		variant = 'tertiary',
		link = vod.vod,
		size = 'sm',
		children = useDropdownVariant and {
			Icon{iconName = 'vod_play'},
			HtmlWidgets.Span{
				children = showText and ('VOD ' .. gameNumber) or gameNumber,
			}
		} or {
			ImageIcon{imageLight = VodLink.getIcon(gameNumber)},
			HtmlWidgets.Span{
				classes = {'match-button-cta-text'},
				children = 'Watch VOD',
			},
		},
	}
end

return VodButton
