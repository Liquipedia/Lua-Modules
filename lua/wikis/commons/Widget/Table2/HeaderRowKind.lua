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

---@return Table2HeaderRowKindName
function Table2HeaderRowKind:getValue()
	return assert(self.props.value, 'Table2HeaderRowKind: expected value')
end

return Table2HeaderRowKind
