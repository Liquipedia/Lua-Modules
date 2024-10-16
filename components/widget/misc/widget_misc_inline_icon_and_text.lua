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
	flipped = false,
}

---@return Widget
function InlineIconAndText:render()
	local children = {
		self.props.icon,
		' ',
		Link{
			link = self.props.link,
			linktype = 'internal',
			children = {self.props.text}
		},
	}

	return Span{
		classes = {'image-link'},
		children = self.props.flipped and Array.reverse(children) or children,
	}
end

return InlineIconAndText
