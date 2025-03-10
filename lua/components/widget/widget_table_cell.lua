---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class WidgetCellInput
---@field children (string|number|table|Html)[]?
---@field classes string[]?
---@field css {[string]: string|number}?

---@class WidgetTableCell:Widget
---@operator call(WidgetCellInput): WidgetTableCell
---@field classes string[]
---@field css {[string]: string|number}
---@field rowSpan integer?
---@field colSpan integer?
local TableCell = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@return Widget
function TableCell:render()
	local styles = Table.copy(self.css)
	styles['grid-row'] = self.rowSpan and 'span ' .. self.rowSpan or nil
	styles['grid-column'] = self.colSpan and 'span ' .. self.colSpan or nil
	return HtmlWidgets.Div{
		classes = WidgetUtil.collect('csstable-widget-cell', unpack(self.classes)),
		css = styles,
		children = self.props.children
	}
end

return TableCell
