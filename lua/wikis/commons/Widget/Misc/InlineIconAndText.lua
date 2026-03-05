---
-- @Liquipedia
-- page=Module:Widget/Misc/InlineIconAndText
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

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
		Logic.isNotEmpty(self.props.link) and Link{
			link = self.props.link,
			linktype = 'internal',
			children = {self.props.text}
		} or self.props.text,
	}

	return Span{
		classes = {'image-link'},
		children = self.props.flipped and Array.reverse(children) or children,
	}
end

return InlineIconAndText
