---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetTableInput
---@field children WidgetTableRow[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field columns integer?

---@class WidgetTable:Widget
---@operator call(WidgetTableInput):WidgetTable
---@field classes string[]
---@field css {[string]: string|number|nil}
---@field columns integer?
local Table = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
		self.css = input.css or {}
		self.columns = input.columns
	end
)

---@param row WidgetTableRow?
---@return self
function Table:addRow(row)
	table.insert(self.children, row)
	return self
end

---@param class string
---@return self
function Table:addClass(class)
	table.insert(self.classes, class)
	return self
end

---@param children string[]
---@return string?
function Table:make(children)
	local displayTable = mw.html.create('div'):addClass('csstable-widget')
	displayTable:css{
		['grid-template-columns'] = 'repeat(' .. (self.columns or self:_getMaxCells()) .. ', auto)',
	}

	for _, class in ipairs(self.classes) do
		displayTable:addClass(class)
	end

	displayTable:css(self.css)

	for _, row in ipairs(children) do
		displayTable:node(row)
	end

	return tostring(displayTable)
end

---@return integer?
function Table:_getMaxCells()
	local getNumberCells = function(row)
		return row:getCellCount()
	end
	return Array.reduce(Array.map(self.children, getNumberCells), math.max)
end

return Table
