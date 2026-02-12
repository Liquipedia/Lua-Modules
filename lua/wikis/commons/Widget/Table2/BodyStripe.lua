---
-- @Liquipedia
-- page=Module:Widget/Table2/BodyStripe
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local WidgetContext = Lua.import('Module:Widget/Context')

---@alias Table2BodyStripeName 'odd'|'even'

---@class Table2BodyStripe: WidgetContext
---@operator call(table): Table2BodyStripe
local Table2BodyStripe = Class.new(WidgetContext)

---@return Table2BodyStripeName|any
function Table2BodyStripe:getValue()
	return assert(self.props.value, 'Table2BodyStripe: expected value')
end

return Table2BodyStripe
