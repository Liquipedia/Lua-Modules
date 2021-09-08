---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local Table = require('Module:Table')

local Center = Class.new(
	Widget,
	function(self, input)
		self.content = input.content
		self.style = input.style
	end
)

function Center:make()
	return {
		Center:_create(self.content, self.style)
	}
end

function Center:_create(content, style)
	if Table.isEmpty(content) then
		return nil
	end

	local centered = mw.html.create('div'):addClass('infobox-center'):cssText(style)

	for _, item in pairs(content) do
		centered:wikitext(item)
	end

	return mw.html.create('div'):node(centered)
end

return Center
