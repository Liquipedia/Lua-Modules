---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Th
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetTh: Widget
local Th = Class.new(Widget)

---@return Html
function Th:render()
	local th = mw.html.create('th')
	th:attr('colspan', self.props.colSpan)
	th:attr('rowspan', self.props.rowSpan)

	Array.forEach(self.props.classes or {}, FnUtil.curry(th.addClass, th))
	Array.forEach(self.props.children, function(child)
		if Class.instanceOf(child, Widget) then
			child.context = self:_nextContext()
			th:node(child:tryMake())
		else
			th:node(child)
		end
	end)
	return th
end

return Th
