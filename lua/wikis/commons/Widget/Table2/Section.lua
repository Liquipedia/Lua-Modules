---
-- @Liquipedia
-- page=Module:Widget/Table2/Section
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local WidgetContext = Lua.import('Module:Widget/Context')

---@alias Table2SectionName 'head'|'body'

---@class Table2Section: WidgetContext
---@operator call(table): Table2Section
local Table2Section = Class.new(WidgetContext)

---@param default any
---@return Table2SectionName|any
function Table2Section:getValue(default)
	assert(self.props.value ~= nil, 'Table2Section: expected value')
	return self.props.value
end

return Table2Section
