---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local WidgetFactory = require('Module:Infobox/Widget/Factory')

local TableRow = Class.new(
	Widget,
	function(self, input)
		self.tableCells = input.cells or {}
		self.classes = input.classes or {}
	end
)

function TableRow:addTableCell(tableCell)
	table.insert(self.tableData, tableCell)
	return self
end

function TableRow:addClass(class)
	table.insert(self.classes, class)
	return self
end

function TableRow:make()
	local row = mw.html.create('tr')
	for _, class in ipairs(self.classes) do
		row:addClass(class)
	end
	for _, tableCell in ipairs(self.tableCells) do
		row:node(WidgetFactory.work(tableCell, self.injector))
	end
	return row
end

return TableRow
