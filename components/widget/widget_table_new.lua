---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/New
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetTableNewInput
---@field children Widget[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?

---@class WidgetTableNew:Widget
---@operator call(WidgetTableNewInput):WidgetTableNew
---@field classes string[]
---@field css {[string]: string|number|nil}
local Table = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@param injector WidgetInjector?
---@param children string[]
---@return {[1]: Html}
function Table:make(injector, children)
	local wrapper = mw.html.create('div'):addClass('table-responsive')
	local output = mw.html.create('table'):addClass('wikitable')

	Array.forEach(self.classes, FnUtil.curry(output.addClass, output))

	output:css(self.css)

	Array.forEach(children, FnUtil.curry(output.node, output))

	wrapper:node(output)
	return {wrapper}
end

return Table
