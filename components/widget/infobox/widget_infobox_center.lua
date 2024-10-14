---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Center
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')

---@class CentereWidget: Widget
---@operator call(table): CentereWidget
---@field classes string[]
local Center = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes
	end
)

---@param children string[]
---@return string?
function Center:make(children)
	return Center:_create(children, self.classes)
end

---@param content (string|number)[]
---@param classes string[]
---@return string?
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

	return tostring(mw.html.create('div'):node(centered))
end

return Center
