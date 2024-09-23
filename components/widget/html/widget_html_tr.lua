---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tr
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetTr: Widget
local Tr = Class.new(Widget)

---@return Html
function Tr:render()
	local tr = mw.html.create('tr')
	Array.forEach(self.props.classes or {}, FnUtil.curry(tr.addClass, tr))
	Array.forEach(self.props.children, function(child)
		if Class.instanceOf(child, Widget) then
			child.context = self:_nextContext()
			tr:node(child:tryMake())
		else
			tr:node(child)
		end
	end)
	return tr
end

return Tr
