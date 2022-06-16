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
	local table = mw.html.create('div'):addClass('divTable')

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

return Table
