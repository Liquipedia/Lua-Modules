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
		self.cells = input.cells or {}
		self.classes = input.classes or {}
		self.css = input.css or {}
		self.isHeader = (input.isHeader == true)
	end
)

function TableRow:addCell(cell)
	table.insert(self.cells, cell)
	return self
end

function TableRow:addClass(class)
	table.insert(self.classes, class)
	return self
end

function TableRow:make()
	local row = mw.html.create('div'):addClass('divRow')

	if self.isHeader == true then
		row:addClass('divHeaderRow')
	end

	for _, class in ipairs(self.classes) do
		row:addClass(class)
	end

	row:css(self.css)

	for _, cell in ipairs(self.cells) do
		for _, node in ipairs(WidgetFactory.work(cell, self.injector)) do
			row:node(node)
		end
	end

	return {row}
end

return TableRow
