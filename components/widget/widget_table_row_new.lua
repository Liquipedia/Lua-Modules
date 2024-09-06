---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Row/New
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory')

---@class WidgetTableRowNewInput
---@field children Widget[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?

---@class WidgetTableRowNew:Widget
---@operator call(WidgetTableRowNewInput): WidgetTableRowNew
---@field children Widget[]
---@field classes string[]
---@field css {[string]: string|number|nil}
local TableRow = Class.new(
	Widget,
	function(self, input)
		self.children = input.children or {}
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@param injector WidgetInjector?
---@return {[1]: Html}
function TableRow:make(injector)
	local row = mw.html.create('tr')

	Array.forEach(self.classes, FnUtil.curry(row.addClass, row))

	row:css(self.css)

	Array.forEach(self.children, function(child)
		Array.forEach(WidgetFactory.work(child, injector), FnUtil.curry(row.node, row))
	end)

	return {row}
end

return TableRow
