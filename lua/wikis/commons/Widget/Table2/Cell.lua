---
-- @Liquipedia
-- page=Module:Widget/Table2/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2CellProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?
---@field align ('left'|'right'|'center')?
---@field nowrap (string|number|boolean)?
---@field colspan integer?
---@field rowspan integer?

---@class Table2Cell: Widget
---@operator call(Table2CellProps): Table2Cell
local Table2Cell = Class.new(Widget)

Table2Cell.defaultProps = {
	classes = {},
	attributes = {},
}

---@return string
local function alignClass(align)
	if align == 'right' then
		return 'table2__cell--right'
	elseif align == 'center' then
		return 'table2__cell--center'
	end
	return 'table2__cell--left'
end

---@return Widget
function Table2Cell:render()
	local attributes = Table.copy(self.props.attributes or {})
	if self.props.colspan ~= nil then
		attributes.colspan = self.props.colspan
	end
	if self.props.rowspan ~= nil then
		attributes.rowspan = self.props.rowspan
	end

	return HtmlWidgets.Td{
		classes = WidgetUtil.collect(
			'table2__cell',
			alignClass(self.props.align),
			Logic.readBool(self.props.nowrap) and 'table2__cell--nowrap' or nil,
			self.props.classes
		),
		css = self.props.css,
		attributes = attributes,
		children = self.props.children,
	}
end

return Table2Cell
