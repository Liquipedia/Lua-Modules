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
	local table = mw.html.create('div')
	table:css{display = 'inline-grid', ['border-right'] = '1px solid #bbb', ['border-bottom'] = '1px solid #bbb'}
	table:css('grid-template-rows', 'repeat(' .. #self.rows .. ', auto)')
	table:css('grid-template-columns', 'repeat(' .. self:_getMaxCells() .. ', auto)')

	for _, class in ipairs(self.classes) do
		table:addClass(class)
	end

	table:css(self.css)

	for _, row in ipairs(self.rows) do
		for _, node in ipairs(WidgetFactory.work(row, self.injector)) do
			table:node(node)
		end
	end

	return {table}
end

function Table:_getMaxCells()
	local getNumberCells = function(row)
		return #row.cells -- Don't like this
	end
	return Array.reduce(Array.map(self.rows, getNumberCells), math.max)
end

return Table
