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

---@class WidgetTableRowNewInput
---@field children Widget[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?

---@class WidgetTableRowNew:Widget
---@operator call(WidgetTableRowNewInput): WidgetTableRowNew
---@field classes string[]
---@field css {[string]: string|number|nil}
local TableRow = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@param injector WidgetInjector?
---@param children string[]
---@return string?
function TableRow:make(injector, children)
	local row = mw.html.create('tr')

	Array.forEach(self.classes, FnUtil.curry(row.addClass, row))

	row:css(self.css)

	Array.forEach(children, FnUtil.curry(row.node, row))

	return tostring(row)
end

return TableRow
