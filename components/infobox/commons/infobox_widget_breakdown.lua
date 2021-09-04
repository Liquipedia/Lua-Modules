---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Breakdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local Table = require('Module:Table')

local Breakdown = Class.new(
	Widget,
	function(self, input)
		self.contents = input.content
	end
)

function Breakdown:make()
	return Breakdown:_breakdown(self.contents)
end

function Breakdown:_breakdown(contents)
mw.logObject(contents)
	if type(contents) ~= 'table' or contents == {} then
		return nil
	end

	local div = mw.html.create('div')
	local number = #contents
	for _, content in ipairs(contents) do
		local infoboxCustomCell = mw.html.create('div'):addClass('infobox-cell-' .. number
			.. ' infobox-center')
		infoboxCustomCell:wikitext(content)
		div:node(infoboxCustomCell)
	end

	return {div}
end

return Breakdown
