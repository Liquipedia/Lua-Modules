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
		self.css = input.css or {}
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
	local cell = mw.html.create('div')
	cell:addClass('divCell'):css('border', '1px solid #bbb'):css('vertical-align', 'middle')

	for _, class in ipairs(self.classes) do
		cell:addClass(class)
	end

	cell:css(self.css)

	cell:wikitext(table.concat(self.content))

	return {cell}
end

return TableCell
