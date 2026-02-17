---
-- @Liquipedia
-- page=Module:Widget/Table2/HeaderRowKind
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local WidgetContext = Lua.import('Module:Widget/Context')

---@class Table2HeaderRowKind: WidgetContext
---@operator call(table): Table2HeaderRowKind
local Table2HeaderRowKind = Class.new(WidgetContext)

return Table2HeaderRowKind
