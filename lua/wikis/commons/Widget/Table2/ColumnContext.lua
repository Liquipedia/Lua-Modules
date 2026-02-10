---
-- @Liquipedia
-- page=Module:Widget/Table2/ColumnContext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2ColumnContext: Widget
---@field columnDefinitions table[]
---@operator call(Table2ColumnContextProps): Table2ColumnContext
local Table2ColumnContext = Class.new(Widget)

Table2ColumnContext.contextKey = 'Table2ColumnContext'

---@class Table2ColumnContextProps
---@field children (Widget|Html|string|number|nil)[]?
---@field columns table[]?

Table2ColumnContext.defaultProps = {
	children = {},
	columns = {},
}

---@return Widget
function Table2ColumnContext:render()
	local props = self.props
	return HtmlWidgets.Fragment{
		children = props.children,
	}
end

return Table2ColumnContext
