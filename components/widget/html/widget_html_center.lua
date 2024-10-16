---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetCenter: WidgetHtmlBase
---@operator call(table): WidgetCenter
local Center = Class.new(WidgetHtml)

---@return Html
function Center:render()
	local attributes = Table.copy(self.props.attributes or {})
	attributes.class = self.props.classes
	attributes.style = self.props.css
	return self:renderAs('center', self.props.children, attributes)
end

return Center
