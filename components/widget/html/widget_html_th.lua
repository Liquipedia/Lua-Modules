---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Th
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetTh: WidgetHtmlBase
---@operator call(table): WidgetTh
local Th = Class.new(WidgetHtml)

---@return Html
function Th:render()
	local attributes = Table.copy(self.props.attributes)
	attributes.class = self.props.classes
	attributes.style = self.props.css
	return self:renderAs('th', self.props.children, attributes)
end

return Th
