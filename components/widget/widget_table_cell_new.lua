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
---@field content (string|number|table|Html)[]?
---@field classes string[]?
---@field css {[string]: string|number}?
---@field rowSpan integer?
---@field colSpan integer?
---@field header boolean?

---@class WidgetTableCellNew:Widget
---@operator call(WidgetCellInputNew): WidgetTableCellNew
---@field content (string|number|table|Html)[]
---@field classes string[]
---@field css {[string]: string|number}
---@field rowSpan integer?
---@field colSpan integer?
---@field isHeader boolean
local TableCell = Class.new(
	Widget,
	function(self, input)
		self.content = input.content or {}
		self.classes = input.classes or {}
		self.css = input.css or {}
		self.rowSpan = input.rowSpan
		self.colSpan = input.colSpan
		self.isHeader = Logic.readBool(input.header)
	end
)

---@param injector WidgetInjector?
---@return {[1]: Html}
function TableCell:make(injector)
	local cell = mw.html.create(self.isHeader and 'th' or 'td')
	cell:attr('colspan', self.colSpan)
	cell:attr('rowspan', self.rowSpan)

	Array.forEach(self.classes, FnUtil.curry(cell.addClass, cell))

	cell:css(self.css)

	cell:node(self:_content())

	return {cell}
end

---@return string
function TableCell:_content()
	return table.concat(Array.map(self.content, function (content)
		if type(content) ~= 'table' then
			return content
		end

		if not Array.isArray(content) then
			return tostring(content)
		end

		local wrapper = mw.html.create('div')
		Array.forEach(content, FnUtil.curry(wrapper.node, wrapper))
		return tostring(wrapper)
	end))
end

return TableCell
