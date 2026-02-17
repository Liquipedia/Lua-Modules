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

---@return Table2SectionName
function Table2Section:getValue()
	return self.props.value
end

return Table2Section
