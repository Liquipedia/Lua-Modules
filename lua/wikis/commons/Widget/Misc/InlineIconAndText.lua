---
-- @Liquipedia
-- page=Module:Widget/Misc/InlineIconAndText
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local Link = Lua.import('Module:Widget/Basic/Link')
local Span = Html.Span

---@class InlineIconAndTextWidgetParameters
---@field icon IconWidget
---@field text string?
---@field link string?
---@field flipped boolean?

---@param props InlineIconAndTextWidgetParameters
---@return VNode
local function InlineIconAndText(props)
	local children = {
		props.icon,
		' ',
		Logic.isNotEmpty(props.link) and Link{
			link = props.link,
			linktype = 'internal',
			children = {props.text}
		} or props.text,
	}

	return Span{
		classes = {'image-link'},
		children = props.flipped and Array.reverse(children) or children,
	}
end

return Component.component(InlineIconAndText, {flipped = false})
