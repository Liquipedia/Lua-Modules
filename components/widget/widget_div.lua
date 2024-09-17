---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Div
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class GenericDivWidget: Widget
---@operator call({children: (Widget|string)[]?}?): GenericDivWidget
---@field classes string[]
local Div = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
	end
)

---@param injector WidgetInjector?
---@param children string[]
---@return string?
function Div:make(injector, children)
	local div = mw.html.create('div')
	Array.forEach(self.classes, FnUtil.curry(div.addClass, div))
	Array.forEach(children, FnUtil.curry(div.node, div))
	return tostring(div)
end

return Div
