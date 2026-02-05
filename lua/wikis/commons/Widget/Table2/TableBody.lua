---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2BodyProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Body: Widget
---@operator call(Table2BodyProps): Table2Body
local Table2Body = Class.new(Widget)
Table2Body.defaultProps = {
	classes = {},
}

---@return Widget
function Table2Body:render()
	return HtmlWidgets.Tbody{
		classes = WidgetUtil.collect('table2__body', self.props.classes),
		css = self.props.css,
		attributes = self.props.attributes,
		children = self.props.children,
	}
end

return Table2Body
