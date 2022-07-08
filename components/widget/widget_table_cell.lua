---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
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
	local cell = mw.html.create('div'):addClass('csstable-widget-cell')
	cell:css{
		['grid-row'] = self.rowSpan and 'span ' .. self.rowSpan or nil,
		['grid-column'] = self.colSpan and 'span ' .. self.colSpan or nil,
	}

	for _, class in ipairs(self.classes) do
		cell:addClass(class)
	end

	cell:css(self.css)

	cell:node(self:_concatContent())

	return {cell}
end

function TableCell:_concatContent()
	return table.concat(Array.map(self.content, function (content)
		if type(content) == 'table' then
			local wrapper = mw.html.create('div')
			Array.forEach(content, function (inner)
				wrapper:node(inner)
			end)
			return tostring(wrapper)
		else
			return content
		end
	end))
end

return TableCell
