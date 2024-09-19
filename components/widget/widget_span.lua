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

---@class GenericSpanWidgetParameters: WidgetParameters
---@field classes string[]?

---@class GenericSpanWidget: Widget
---@operator call(GenericSpanWidgetParameters): GenericSpanWidget
---@field classes string[]
local Span = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
	end
)

---@param children string[]
---@return string?
function Span:make(children)
	local span = mw.html.create('span')
	Array.forEach(self.classes, FnUtil.curry(span.addClass, span))
	Array.forEach(children, FnUtil.curry(span.node, span))
	return tostring(span)
end

return Span
