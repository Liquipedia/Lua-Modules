---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')

local TableCell = Class.new(
	Widget,
	function(self, input)
		self.content = input.content or {}
		self.classes = input.classes or {}
		self.isHeader = input.isHeader and true or false
	end
)

function TableCell:addContent(text)
	table.insert(self.content, text)
	return self
end

function TableCell:addClass(class)
	table.insert(self.classes, class)
	return self
end

function TableCell:make()
	local cell
	if self.isHeader then
		cell = mw.html.create('th')
	else
		cell = mw.html.create('td')
	end

	for _, class in ipairs(self.classes) do
		cell:addClass(class)
	end

	cell:wikitext(table.concat(self.content))
	return cell
end

return TableCell
