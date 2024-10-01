---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Span
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetSpan: WidgetHtmlBase
---@operator call(table): WidgetSpan
local Span = Class.new(WidgetHtml)

---@return Html
function Span:render()
	local attributes = Table.copy(self.props.attributes or {})
	attributes.class = self.props.classes
	attributes.style = self.props.css
	return self:renderAs('span', self.children, attributes)
end

return Span
