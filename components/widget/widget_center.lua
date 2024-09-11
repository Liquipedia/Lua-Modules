---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')

---@class CentereWidget: Widget
---@operator call({content: (string|number)[], classes: string[]}): CentereWidget
---@field content (string|number)[]
---@field classes string[]
local Center = Class.new(
	Widget,
	function(self, input)
		self.content = input.content
		self.classes = input.classes
	end
)

---@param injector WidgetInjector?
---@return {[1]: Html?}
function Center:make(injector)
	return {Center:_create(self.content, self.classes)}
end

---@param content (string|number)[]
---@param classes string[]
---@return Html?
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
