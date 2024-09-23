---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Td
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetTd: Widget
local Td = Class.new(Widget)

---@return Html
function Td:render()
	local td = mw.html.create('td')
	td:attr('colspan', self.props.colSpan)
	td:attr('rowspan', self.props.rowSpan)

	Array.forEach(self.props.classes or {}, FnUtil.curry(td.addClass, td))
	Array.forEach(self.props.children, function(child)
		if Class.instanceOf(child, Widget) then
			---@cast child Widget
			child.context = self:_nextContext()
			td:node(child:tryMake())
		else
			td:node(child)
		end
	end)
	return td
end

return Td
