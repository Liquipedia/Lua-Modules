---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Span
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetSpan: Widget
---@operator call(table): WidgetSpan
local Span = Class.new(Widget)

---@return Html
function Span:render(children)
	local span = mw.html.create('span')
	Array.forEach(self.props.classes, FnUtil.curry(span.addClass, span))
	Array.forEach(self.props.children, function(child)
		if Class.instanceOf(child, Widget) then
			child.context = self:_nextContext()
			span:node(child:tryMake())
		else
			span:node(child)
		end
	end)
	return span
end

return Span
