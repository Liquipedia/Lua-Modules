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
local Span = HtmlWidgets.Span
local Div = HtmlWidgets.Div

---@class DropdownItemWidgetParameters
---@field icon string?
---@field text string
---@field link string?
---@field classes table?
---@field attributes table?

---@class DropdownItemWidget: Widget
---@operator call(DropdownItemWidgetParameters): DropdownItemWidget
local DropdownItem = Class.new(Widget)

---@return Widget
function DropdownItem:render()
	local content = {}
	if self.props.icon then
		table.insert(content, Span{
			classes = {'dropdown-widget__item-icon'},
			children = {self.props.icon}
		})
	end
	table.insert(content, Span{
		classes = {'dropdown-widget__item-text'},
		children = {self.props.text}
	})

	local item = Div{
		classes = Array.extend({'dropdown-widget__item'}, self.props.classes or {}),
		attributes = self.props.attributes,
		children = content
	}

	if self.props.link then
		local Link = Lua.import('Module:Widget/Basic/Link')
		return Link{
			link = self.props.link,
			children = {item}
		}
	end

	return item
end

return DropdownItem
