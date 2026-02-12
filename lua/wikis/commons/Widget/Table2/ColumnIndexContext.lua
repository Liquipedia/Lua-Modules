---
-- @Liquipedia
-- page=Module:Widget/Table2/ColumnIndexContext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')
local WidgetContext = Lua.import('Module:Widget/Context')

---@class Table2ColumnIndexContext: WidgetContext
---@operator call(table): Table2ColumnIndexContext
local Table2ColumnIndexContext = Class.new(WidgetContext)

---@return integer
function Table2ColumnIndexContext:getValue()
	assert(MathUtil.isInteger(self.props.value), 'Table2ColumnIndexContext: expected integer')
	return self.props.value
end

return Table2ColumnIndexContext
