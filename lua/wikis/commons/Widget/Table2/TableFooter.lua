---
-- @Liquipedia
-- page=Module:Widget/Table2/TableFooter
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2FooterProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Footer: Widget
---@operator call(Table2FooterProps): Table2Footer
local Table2Footer = Class.new(Widget)
Table2Footer.defaultProps = {
	classes = {},
}

---@return Widget
function Table2Footer:render()
	return HtmlWidgets.Tfoot{
		classes = WidgetUtil.collect('table2__foot', self.props.classes),
		css = self.props.css,
		attributes = self.props.attributes,
		children = self.props.children,
	}
end

return Table2Footer
