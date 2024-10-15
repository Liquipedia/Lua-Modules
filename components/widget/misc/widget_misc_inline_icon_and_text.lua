---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Misc/InlineIconAndText
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span

---@class InlineIconAndTextWidgetParameters
---@field icon IconWidget
---@field text string?
---@field link string?

---@class InlineIconAndTextWidget: Widget
---@operator call(InlineIconAndTextWidgetParameters): InlineIconAndTextWidget

local InlineIconAndText = Class.new(Widget)
InlineIconAndText.defaultProps = {
	options = {
		flipped = false,
	},
}

---@return Widget
function InlineIconAndText:render()
	local children = {
		Link{
			link = self.props.link,
			linktype = 'internal',
			children = {self.props.text}
		},
		' ',
		self.props.icon,
	}
	if self.props.options.flipped then
		children = Array.reverse(children)
	end
	return Span{
		classes = {'image-link'},
		children = children,
	}
end

return InlineIconAndText
