---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')

---@class WidgetHtmlBase: Widget
---@operator call(table): WidgetHtmlBase
local HtmlBase = Class.new(Widget)

---@return Html
function HtmlBase:render()
	error('HtmlBase:render() must be overridden')
end

function HtmlBase:renderAs(tag)
	local attributes = Table.copy(self.props.attributes or {})
	local htmlNode = mw.html.create(tag)
	htmlNode:addClass(table.concat(attributes.class or self.props.classes or {}, ' '))
	htmlNode:css(attributes.style or {})
	attributes.class = nil
	attributes.style = nil
	htmlNode:attr(attributes)

	Array.forEach(self.props.children, function(child)
		if Class.instanceOf(child, Widget) then
			child.context = self:_nextContext()
			htmlNode:node(child:tryMake())
		else
			htmlNode:node(child)
		end
	end)
	return htmlNode
end

return HtmlBase
