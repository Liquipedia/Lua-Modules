---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Div
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetDiv: Widget
---@operator call(table): WidgetDiv
local Div = Class.new(Widget)

---@return Html
function Div:render()
	local div = mw.html.create('div')
	Array.forEach(self.props.classes or {}, FnUtil.curry(div.addClass, div))
	Array.forEach(self.props.children, function(child)
		if Class.instanceOf(child, Widget) then
			child.context = self:_nextContext()
			div:node(child:tryMake())
		else
			div:node(child)
		end
	end)
	return div
end

return Div
