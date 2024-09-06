---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory')

---@class WidgetTableRowInput
---@field cells Widget[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?

---@class WidgetTableRow:Widget
---@operator call(WidgetTableRowInput): WidgetTableRow
---@field cells Widget[]
---@field classes string[]
---@field css {[string]: string|number|nil}
local TableRow = Class.new(
	Widget,
	function(self, input)
		self.cells = input.cells or {}
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@param cell Widget?
---@return self
function TableRow:addCell(cell)
	table.insert(self.cells, cell)
	return self
end

---@param class string|nil
---@return self
function TableRow:addClass(class)
	table.insert(self.classes, class)
	return self
end

---@param key string
---@param value string|number|nil
---@return self
function TableRow:addCss(key, value)
	self.css[key] = value
	return self
end

---@return integer
function TableRow:getCellCount()
	return #self.cells
end

---@param injector WidgetInjector?
---@return {[1]: Html}
function TableRow:make(injector)
	local row = mw.html.create('div'):addClass('csstable-widget-row')

	for _, class in ipairs(self.classes) do
		row:addClass(class)
	end

	row:css(self.css)

	for _, cell in ipairs(self.cells) do
		for _, node in ipairs(WidgetFactory.work(cell, injector)) do
			row:node(node)
		end
	end

	return {row}
end

return TableRow
