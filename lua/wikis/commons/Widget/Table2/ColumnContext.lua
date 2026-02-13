---
-- @Liquipedia
-- page=Module:Widget/Table2/ColumnContext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local WidgetContext = Lua.import('Module:Widget/Context')

---@class Table2ColumnContext: WidgetContext
---@operator call(Table2ColumnContextProps): Table2ColumnContext
local Table2ColumnContext = Class.new(WidgetContext)

---@class Table2ColumnContextProps
---@field children (Widget|Html|string|number|nil)[]?
---@field columns table[]?

---@return {columns: table[]?}
function Table2ColumnContext:getValue()
	return {
		columns = self.props.columns,
	}
end

return Table2ColumnContext
