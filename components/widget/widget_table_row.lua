---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class WidgetTableRowInput
---@field children Widget[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?

---@class WidgetTableRow:Widget
---@operator call(WidgetTableRowInput): WidgetTableRow
---@field classes string[]
---@field css {[string]: string|number|nil}
local TableRow = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@return integer
function TableRow:getCellCount()
	return #self.props.children
end

---@return Widget
function TableRow:render()
	return HtmlWidgets.Div{
		classes = WidgetUtil.collect('csstable-widget-row', unpack(self.classes)),
		css = self.css,
		children = self.props.children
	}
end

return TableRow
