---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetTable: WidgetHtmlBase
---@operator call(table): WidgetTable
local Table = Class.new(WidgetHtml)

---@return Html
function Table:render()
	return self:renderAs('table')
end

return Table
