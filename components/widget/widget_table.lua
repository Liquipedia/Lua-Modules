---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetTableOld: Widget
local Table = Class.new(Widget)

---@return Html
function Table:render()
	local table = mw.html.create('table')
	Array.forEach(self.props.classes, FnUtil.curry(table.addClass, table))
	Array.forEach(self.props.children, function(child)
		if Class.instanceOf(child, Widget) then
			child.context = Widget._nextContext(self.context, self)
			table:node(child:tryMake())
		else
			table:node(child)
		end
	end)
	return table
end

return Table
