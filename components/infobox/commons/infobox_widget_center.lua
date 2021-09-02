---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')

local Center = Class.new(
	Widget,
	function(self, input)
		self.content = input.content
	end
)

function Center:make()
	return {
		Center:_create(self.content)
	}
end

function Center:_create(content)
	local centered = mw.html.create('div'):addClass('infobox-center')

	for _, item in pairs(content) do
		centered:wikitext(item)
	end

	return mw.html.create('div'):node(centered)
end

return Center
