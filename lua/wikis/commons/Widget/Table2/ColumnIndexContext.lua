---
-- @Liquipedia
-- page=Module:Widget/Table2/ColumnIndexContext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local WidgetContext = Lua.import('Module:Widget/Context')

---@class Table2ColumnIndexContext: WidgetContext
---@operator call(table): Table2ColumnIndexContext
local Table2ColumnIndexContext = Class.new(WidgetContext)

---@param default any
---@return integer|any
function Table2ColumnIndexContext:getValue(default)
	assert(self.props.value ~= nil, 'Table2ColumnIndexContext: expected value')
	return self.props.value
end

return Table2ColumnIndexContext
