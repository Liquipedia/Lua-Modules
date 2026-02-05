---
-- @Liquipedia
-- page=Module:Widget/Table2/TableHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2HeaderProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Header: Widget
---@operator call(Table2HeaderProps): Table2Header
local Table2Header = Class.new(Widget)
Table2Header.defaultProps = {
	classes = {},
}

---@return Widget
function Table2Header:render()
	return HtmlWidgets.Thead{
		classes = WidgetUtil.collect('table2__head', self.props.classes),
		css = self.props.css,
		attributes = self.props.attributes,
		children = self.props.children,
	}
end

return Table2Header
