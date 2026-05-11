---
-- @Liquipedia
-- page=Module:Widget/Basic/Dropdown/Item
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class DropdownItemWidgetParameters: LinkWidgetParameters
---@field icon string|Widget?
---@field classes string[]?
---@field attributes table?

local DropdownItem = {}
DropdownItem.defaultProps = {
	linktype = 'internal',
}

---@param props DropdownItemWidgetParameters
---@return HtmlNode
function DropdownItem.render(props)
	local icon = Logic.isNotEmpty(props.icon) and
		(type(props.icon) == 'string' and Icon{iconName = props.icon --[[@as string]], size = 'sm'} or props.icon)
		or nil

	local children = WidgetUtil.collect(icon, props.children)

	local item = Div{
		classes = Array.extend('dropdown-widget__item', props.classes),
		attributes = props.attributes,
		children = children
	}

	if not props.link then
		return item
	end

	return Div{
		children = {
			Link{
				link = props.link,
				linktype = props.linktype,
				children = {item}
			}
		}
	}
end

return Component.component(DropdownItem.render, DropdownItem.defaultProps)
