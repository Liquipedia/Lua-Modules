---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Td
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetTd: WidgetHtmlBase
---@operator call(table): WidgetTd
local Td = Class.new(WidgetHtml)

---@return Html
function Td:render()
	return self:renderAs('td')
end

return Td
