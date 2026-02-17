---
-- @Liquipedia
-- page=Module:Widget/Table2/BodyStripe
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local WidgetContext = Lua.import('Module:Widget/Context')

---@class Table2BodyStripe: WidgetContext
---@operator call(table): Table2BodyStripe
local Table2BodyStripe = Class.new(WidgetContext)

return Table2BodyStripe
