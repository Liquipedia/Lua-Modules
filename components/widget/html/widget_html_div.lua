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
	local attributes = Table.copy(self.props.attributes)
	attributes.class = self.props.classes
	attributes.style = self.props.css
	return self:renderAs('div', self.props.children, attributes)
end

return Div
