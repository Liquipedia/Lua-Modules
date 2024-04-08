---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/New
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Infobox/Widget')
local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory')

---@class WidgetTableNewInput
---@field children Widget[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?

---@class WidgetTableNew:Widget
---@operator call(WidgetTableNewInput):WidgetTableNew
---@field children Widget[]
---@field classes string[]
---@field css {[string]: string|number|nil}
local Table = Class.new(
	Widget,
	function(self, input)
		self.children = input.children or {}
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@param injector WidgetInjector?
---@return {[1]: Html}
function Table:make(injector)
	local wrapper = mw.html.create('div'):addClass('table-responsive')
	local displayTable = mw.html.create('table'):addClass('wikitable')

	for _, class in ipairs(self.classes) do
		displayTable:addClass(class)
	end

	displayTable:css(self.css)

	for _, row in ipairs(self.children) do
		for _, node in ipairs(WidgetFactory.work(row, injector)) do
			displayTable:node(node)
		end
	end

	wrapper:node(displayTable)
	return {wrapper}
end

return Table
