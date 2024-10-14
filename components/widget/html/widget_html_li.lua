---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Li
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetHtml = Lua.import('Module:Widget/Html/Base')

---@class WidgetLi: WidgetHtmlBase
---@operator call(table): WidgetLi
local Li = Class.new(WidgetHtml)

---@return Html
function Li:render()
	local attributes = Table.copy(self.props.attributes or {})
	attributes.class = self.props.classes
	attributes.style = self.props.css
	return self:renderAs('li', self.props.children, attributes)
end

return Li
