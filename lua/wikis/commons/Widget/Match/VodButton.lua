---
-- @Liquipedia
-- page=Module:Widget/Match/VodButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
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
	local vodLink = self.props.vodLink

	if not vodLink then
		return
	end

	local useDropdownVariant = self.props.variant == 'dropdown'
	local showText = self.props.showText
	local gameNumber = self.props.gameNumber
	local useGrow = Logic.readBool(self.props.grow)

	return Button{
		linktype = 'external',
		title = VodLink.getTitle(gameNumber),
		variant = 'tertiary',
		link = vodLink,
		size = 'sm',
		grow = useGrow,
		children = useDropdownVariant and {
			Icon{iconName = 'vod_play', size = 'sm'},
			HtmlWidgets.Span{
				children = showText and ('Game ' .. gameNumber) or gameNumber,
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
