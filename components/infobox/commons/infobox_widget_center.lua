---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Infobox/Widget', {requireDevIfEnabled = true})

local Center = Class.new(
	Widget,
	function(self, input)
		self.content = input.content
		self.classes = input.classes
	end
)

function Center:make()
	return {
		Center:_create(self.content, self.classes)
	}
end

function Center:_create(content, classes)
	if Table.isEmpty(content) then
		return nil
	end

	local centered = mw.html.create('div'):addClass('infobox-center')
	for _, class in ipairs(classes or {}) do
		centered:addClass(class)
	end

	for _, item in pairs(content) do
		centered:wikitext(item)
	end

	return mw.html.create('div'):node(centered)
end

return Center
