---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Breakdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')

local Breakdown = Class.new(
	Widget,
	function(self, input)
		self.contents = input.content
		self.classes = input.classes
	end
)

function Breakdown:make()
	return {Breakdown:_breakdown(self.contents, self.classes)}
end

function Breakdown:_breakdown(contents, classes)
	if type(contents) ~= 'table' or contents == {} then
		return nil
	end

	local div = mw.html.create('div')
	local number = #contents
	for _, content in ipairs(contents) do
		local infoboxCustomCell = mw.html.create('div'):addClass('infobox-cell-' .. number)
		for _, class in pairs(classes or {}) do
			infoboxCustomCell:addClass(class)
		end
		infoboxCustomCell:wikitext(content)
		div:node(infoboxCustomCell)
	end

	return div
end

return Breakdown
