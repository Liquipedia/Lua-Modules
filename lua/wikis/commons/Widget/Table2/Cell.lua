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
local Table2ColumnContext = Lua.import('Module:Widget/Table2/ColumnContext')
local Table2ColumnIndexContext = Lua.import('Module:Widget/Table2/ColumnIndexContext')
local ColumnUtil = Lua.import('Module:Widget/Table2/ColumnUtil')

---@class Table2CellProps
---@field children (Widget|Html|string|number|nil)[]?
---@field align ('left'|'right'|'center')?
---@field shrink (string|number|boolean)?
---@field nowrap (string|number|boolean)?
---@field width string?
---@field minWidth string?
---@field maxWidth string?
---@field colspan integer?
---@field rowspan integer?
---@field columnIndex integer?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Cell: Widget
---@operator call(Table2CellProps): Table2Cell
local Table2Cell = Class.new(Widget)

Table2Cell.defaultProps = {
	classes = {},
	attributes = {},
}

---@return Widget
function Table2Cell:render()
	local props = self.props

	local columnContext = self:useContext(Table2ColumnContext)
	local columnIndexContext = self:useContext(Table2ColumnIndexContext)
	local columnDef = nil
	local columnIndex = ColumnUtil.getColumnIndex(props.columnIndex, columnIndexContext)

	if columnContext and columnContext.columns and columnContext.columns[columnIndex] then
		columnDef = columnContext.columns[columnIndex]
	end

	local mergedProps = ColumnUtil.mergeProps(props, columnDef)

	local attributes = Table.copy(mergedProps.attributes or {})
	if mergedProps.colspan ~= nil then
		attributes.colspan = mergedProps.colspan
	end
	if mergedProps.rowspan ~= nil then
		attributes.rowspan = mergedProps.rowspan
	end

	local css = ColumnUtil.buildCss(
		Logic.readBool(mergedProps.shrink),
		mergedProps.width,
		mergedProps.minWidth,
		mergedProps.maxWidth,
		mergedProps.css
	)

	local classes = ColumnUtil.buildClasses(
		mergedProps.align,
		mergedProps.nowrap,
		mergedProps.shrink,
		mergedProps.classes
	)

	return HtmlWidgets.Td{
		classes = WidgetUtil.collect('table2__cell', classes),
		css = css,
		attributes = attributes,
		children = mergedProps.children,
	}
end

return Table2Cell
