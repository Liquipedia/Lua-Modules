---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetTable: WidgetHtmlBase
---@operator call(table): WidgetTable
local HtmlTable = Class.new(WidgetHtml)

---@return Html
function HtmlTable:render()
	local attributes = Table.copy(self.props.attributes or {})
	attributes.class = self.props.classes
	attributes.style = self.props.css
	return self:renderAs('table', self.props.children, attributes)
end

return HtmlTable
