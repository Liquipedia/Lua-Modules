---
-- @Liquipedia
-- page=Module:Widget/Table2/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Table2ColumnContext = Lua.import('Module:Widget/Table2/ColumnContext')
local ColumnUtil = Lua.import('Module:Widget/Table2/ColumnUtil')

---@class Table2CellProps
---@field children (Widget|Html|string|number|nil)[]?
---@field align ('left'|'right'|'center')?
---@field shrink (string|number|boolean)?
---@field nowrap (string|number|boolean)?
---@field width string?
---@field minWidth string?
---@field maxWidth string?
---@field colspan integer|string?
---@field rowspan integer|string?
---@field columnIndex integer|string?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Cell: Widget
---@operator call(Table2CellProps): Table2Cell
---@field props Table2CellProps
local Table2Cell = Class.new(Widget)

---@return Widget
function Table2Cell:render()
	local props = self.props

	local columnContext = self:useContext(Table2ColumnContext)

	-- Skip context lookups and property merging if there are no column definitions
	if not columnContext or not columnContext.columns then
		return HtmlWidgets.Td{
			classes = WidgetUtil.collect('table2__cell', 'table2__cell--left'),
			attributes = props.attributes,
			children = props.children,
		}
	end

	local columnDef
	local columnIndex = ColumnUtil.getColumnIndex(props.columnIndex, nil)

	if columnContext.columns[columnIndex] then
		columnDef = columnContext.columns[columnIndex]
	end

	local mergedProps = ColumnUtil.mergeProps(props, columnDef)

	local attributes = ColumnUtil.buildAttributes(mergedProps)

	local css = ColumnUtil.buildCss(mergedProps.width, mergedProps.minWidth, mergedProps.maxWidth, mergedProps.css)

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
