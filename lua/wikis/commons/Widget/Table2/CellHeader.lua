---
-- @Liquipedia
-- page=Module:Widget/Table2/CellHeader
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
local ColumnUtil = Lua.import('Module:Widget/util/ColumnUtil')

---@class Table2CellHeaderProps
---@field children (Widget|Html|string|number|nil)[]?
---@field align ('left'|'right'|'center')?
---@field nowrap (string|number|boolean)?
---@field unsortable (string|number|boolean)?
---@field sortType string?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?
---@field colspan integer?
---@field rowspan integer?
---@field columnIndex integer?

---@class Table2CellHeader: Widget
---@operator call(Table2CellHeaderProps): Table2CellHeader
local Table2CellHeader = Class.new(Widget)

Table2CellHeader.defaultProps = {
	classes = {},
	attributes = {},
}

---Gets the column index for this cell
---@param columnIndexProp integer|nil - explicit column index from props
---@return integer
local function getColumnIndex(columnIndexProp)
	return columnIndexProp or 1
end

---@return Widget
function Table2CellHeader:render()
	local props = self.props

	local columnContext = self:useContext(Table2ColumnContext.contextKey)
	local columnDef = nil
	local columnIndex = getColumnIndex(props.columnIndex)

	if columnContext and columnContext.columns and columnContext.columns[columnIndex] then
		columnDef = columnContext.columns[columnIndex]
	end

	local mergedProps = ColumnUtil.mergeProps(props, columnDef)

	local classes = mergedProps.classes
	if Logic.readBool(mergedProps.unsortable) then
		classes = WidgetUtil.collect(classes, 'unsortable')
	end

	local attributes = Table.copy(mergedProps.attributes or {})
	if mergedProps.sortType ~= nil then
		attributes['data-sort-type'] = mergedProps.sortType
	end
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

	local headerClasses = ColumnUtil.buildClasses(
		mergedProps.align,
		mergedProps.nowrap,
		mergedProps.shrink,
		classes
	)

	return HtmlWidgets.Th{
		classes = WidgetUtil.collect('table2__cell', headerClasses),
		css = css,
		attributes = attributes,
		children = mergedProps.children,
	}
end

return Table2CellHeader
