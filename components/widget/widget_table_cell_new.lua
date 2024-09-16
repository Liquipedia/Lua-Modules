---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Cell/New
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetCellInputNew
---@field content (Widget|Html|string|number)[]
---@field classes string[]?
---@field css {[string]: string|number}?
---@field rowSpan integer?
---@field colSpan integer?
---@field header boolean?

---@class WidgetTableCellNew:Widget
---@operator call(WidgetCellInputNew): WidgetTableCellNew
---@field classes string[]
---@field css {[string]: string|number}
---@field rowSpan integer?
---@field colSpan integer?
---@field isHeader boolean
local TableCell = Class.new(
	Widget,
	function(self, input)
		self.children = input.children or input.content or {} -- TODO remove input.content
		self.classes = input.classes or {}
		self.css = input.css or {}
		self.rowSpan = input.rowSpan
		self.colSpan = input.colSpan
		self.isHeader = Logic.readBool(input.header)
	end
)

---@param injector WidgetInjector?
---@param children string[]
---@return string?
function TableCell:make(injector, children)
	local cell = mw.html.create(self.isHeader and 'th' or 'td')
	cell:attr('colspan', self.colSpan)
	cell:attr('rowspan', self.rowSpan)

	Array.forEach(self.classes, FnUtil.curry(cell.addClass, cell))

	cell:css(self.css)

	Array.forEach(children, FnUtil.curry(cell.node, cell))

	return tostring(cell)
end

return TableCell
