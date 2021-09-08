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
		self.options = input.options
	end
)

function Breakdown:make()
	return {Breakdown:_breakdown(self.contents, slef.options)}
end

function Breakdown:_breakdown(contents, options)
	if type(contents) ~= 'table' or contents == {} then
		return nil
	end
	options = options or {}

	local div = mw.html.create('div')
	local number = #contents
	for _, content in ipairs(contents) do
		local infoboxCustomCell = mw.html.create('div'):addClass('infobox-cell-' .. number)
		if not options.isNotCentered then
			infoboxCustomCell::addClass('infobox-center')
		end
		infoboxCustomCell:wikitext(content)
		div:node(infoboxCustomCell)
	end

	return div
end

return Breakdown
