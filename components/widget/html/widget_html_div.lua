---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Div
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetDiv: WidgetHtmlBase
---@operator call(table): WidgetDiv
local Div = Class.new(WidgetHtml)

---@return Html
function Div:render()
	return self:renderAs('div')
end

return Div
