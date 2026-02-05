---
-- @Liquipedia
-- page=Module:Widget/Table2/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2RowProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Row: Widget
---@operator call(Table2RowProps): Table2Row
local Table2Row = Class.new(Widget)
Table2Row.defaultProps = {
	classes = {},
}

---@return Widget
function Table2Row:render()
	return HtmlWidgets.Tr{
		classes = WidgetUtil.collect('table2__row', self.props.classes),
		css = self.props.css,
		attributes = self.props.attributes,
		children = self.props.children,
	}
end

return Table2Row
