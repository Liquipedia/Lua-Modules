---
-- @Liquipedia
-- page=Module:Widget/Table2/HeaderRowKind
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local WidgetContext = Lua.import('Module:Widget/Context')

---@alias Table2HeaderRowKindName 'title'|'columns'

---@class Table2HeaderRowKind: WidgetContext
---@operator call(table): Table2HeaderRowKind
local Table2HeaderRowKind = Class.new(WidgetContext)

---@param default any
---@return Table2HeaderRowKindName|any
function Table2HeaderRowKind:getValue(default)
	assert(self.props.value ~= nil, 'Table2HeaderRowKind: expected value')
	return self.props.value
end

return Table2HeaderRowKind
