---
-- @Liquipedia
-- page=Module:Widget/Table2/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')
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

Table2Cell.defaultProps = {
	nowrap = true,
}

---@return Widget
function Table2Cell:render()
	local props = self.props

	local columns = self:useContext(Table2Contexts.ColumnContext)

	-- Skip context lookups and property merging if there are no column definitions
	if not columns then
		return HtmlWidgets.Td{
			attributes = ColumnUtil.buildCellAttributes(
				props.align,
				props.nowrap,
				props.shrink,
				props.attributes
			),
			children = props.children,
		}
	end

	local columnDef
	local columnIndex = ColumnUtil.getColumnIndex(props.columnIndex, nil)

	if columns[columnIndex] then
		columnDef = columns[columnIndex]
	end

	local mergedProps = ColumnUtil.mergeProps(props, columnDef)

	local css = ColumnUtil.buildCss(mergedProps.width, mergedProps.minWidth, mergedProps.maxWidth, mergedProps.css)

	local attributes = ColumnUtil.buildCellAttributes(
		mergedProps.align,
		mergedProps.nowrap,
		mergedProps.shrink,
		ColumnUtil.buildAttributes(mergedProps)
	)

	return HtmlWidgets.Td{
		classes = mergedProps.classes,
		css = css,
		attributes = attributes,
		children = mergedProps.children,
	}
end

return Table2Cell
