---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Span
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetSpan: WidgetHtmlBase
---@operator call(table): WidgetSpan
local Span = Class.new(WidgetHtml)

---@return Html
function Span:render()
	return self:renderAs('span')
end

return Span
