---
-- @Liquipedia
-- page=Module:Widget/Basic/Dropdown/Item
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class DropdownItemWidgetParameters
---@field icon string|Widget?
---@field text string
---@field link string?
---@field linktype 'internal'|'external'|nil
---@field classes table?
---@field attributes table?

---@class DropdownItemWidget: Widget
---@operator call(DropdownItemWidgetParameters): DropdownItemWidget
local DropdownItem = Class.new(Widget)
DropdownItem.defaultProps = {
	linktype = 'internal',
}

---@return Widget
function DropdownItem:render()
	local content = {}
	if self.props.icon then
		local iconWidget
		if type(self.props.icon) == 'string' then
			iconWidget = Icon{iconName = self.props.icon, size = 'sm'}
		else
			iconWidget = self.props.icon
		end
		table.insert(content, iconWidget)
	end
	table.insert(content, self.props.text)

	local item = Div{
		classes = Array.extend({'dropdown-widget__item'}, self.props.classes or {}),
		attributes = self.props.attributes,
		children = content
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
