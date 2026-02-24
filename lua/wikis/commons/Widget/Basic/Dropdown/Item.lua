---
-- @Liquipedia
-- page=Module:Widget/Basic/Dropdown/Item
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class DropdownItemWidgetParameters
---@field icon string|Widget?
---@field children Renderable|Renderable[]
---@field link string?
---@field linktype 'internal'|'external'|nil
---@field classes string[]?
---@field attributes table?

---@class DropdownItemWidget: Widget
---@operator call(DropdownItemWidgetParameters): DropdownItemWidget
---@field props DropdownItemWidgetParameters
local DropdownItem = Class.new(Widget)
DropdownItem.defaultProps = {
	linktype = 'internal',
}

---@return Widget
function DropdownItem:render()
	local icon = not Logic.isEmpty(self.props.icon) and
		(type(self.props.icon) == 'string' and Icon{iconName = self.props.icon, size = 'sm'} or self.props.icon)

	local children = WidgetUtil.collect(icon, self.props.children)

	local item = Div{
		classes = Array.extend('dropdown-widget__item', self.props.classes),
		attributes = self.props.attributes,
		children = children
	}

	if not self.props.link then
		return item
	end

	return Div{
		children = {
			Link{
				link = self.props.link,
				linktype = self.props.linktype,
				children = {item}
			}
		}
	}
end

return DropdownItem
