---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Tr
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetTr: WidgetHtmlBase
---@operator call(table): WidgetTr
local Tr = Class.new(WidgetHtml)

---@return Html
function Tr:render()
	return self:renderAs('tr')
end

return Tr
