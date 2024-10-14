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

---@class WidgetUl: WidgetHtmlBase
---@operator call(table): WidgetUl
local Ul = Class.new(WidgetHtml)

---@return Html
function Ul:render()
	local attributes = Table.copy(self.props.attributes or {})
	attributes.class = self.props.classes
	attributes.style = self.props.css
	return self:renderAs('ul', self.props.children, attributes)
end

return Ul
