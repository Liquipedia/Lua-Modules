---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local WidgetFactory = require('Module:Infobox/Widget/Factory')

local Table = Class.new(
	Widget,
	function(self, input)
		self.rows = input.rows or {}
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

function Table:addRow(row)
	table.insert(self.rows, row)
	return self
end

function Table:addClass(class)
	table.insert(self.classes, class)
	return self
end

function Table:make()
	local displayTable = mw.html.create('div')
	displayTable:css{
		['display'] = 'inline-grid',
		['border-right'] = '1px solid #bbb',
		['border-bottom'] = '1px solid #bbb',
		['grid-template-rows'] = 'repeat(' .. #self.rows .. ', auto)',
		['grid-template-columns'] = 'repeat(' .. self:_getMaxCells() .. ', auto)',
	}

	for _, class in ipairs(self.classes) do
		displayTable:addClass(class)
	end

	displayTable:css(self.css)

	for _, row in ipairs(self.rows) do
		for _, node in ipairs(WidgetFactory.work(row, self.injector)) do
			displayTable:node(node)
		end
	end

	return {displayTable}
end

function Table:_getMaxCells()
	local getNumberCells = function(row)
		return row:getCellCount()
	end
	return Array.reduce(Array.map(self.rows, getNumberCells), math.max)
end

return Table
