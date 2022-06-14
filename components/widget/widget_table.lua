---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local WidgetFactory = require('Module:Infobox/Widget/Factory')

local Table = Class.new(
	Widget,
	function(self, input)
		self.tableRows = input.rows or {}
		self.classes = input.classes or {}
	end
)

function Table:addRow(tableRow)
	table.insert(self.tableRows, tableRow)
	return self
end

function Table:addClass(class)
	table.insert(self.classes, class)
	return self
end

function Table:make()
	local table = mw.html.create('table')
	for _, class in ipairs(self.classes) do
		table:addClass(class)
	end
	for _, tableRow in ipairs(self.tableRows) do
		table:node(WidgetFactory.work(tableRow, self.injector))
	end
	return table
end

return Table
