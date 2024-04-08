---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Row/New
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Infobox/Widget')
local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory')

---@class WidgetTableRowNewInput
---@field children Widget[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?

---@class WidgetTableRowNew:Widget
---@operator call(WidgetTableRowNewInput): WidgetTableRowNew
---@field children Widget[]
---@field classes string[]
---@field css {[string]: string|number|nil}
local TableRow = Class.new(
	Widget,
	function(self, input)
		self.children = input.children or {}
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@param injector WidgetInjector?
---@return {[1]: Html}
function TableRow:make(injector)
	local row = mw.html.create('tr')

	for _, class in ipairs(self.classes) do
		row:addClass(class)
	end

	row:css(self.css)

	for _, cell in ipairs(self.children) do
		for _, node in ipairs(WidgetFactory.work(cell, injector)) do
			row:node(node)
		end
	end

	return {row}
end

return TableRow
