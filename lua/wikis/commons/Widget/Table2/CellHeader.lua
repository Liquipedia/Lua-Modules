---
-- @Liquipedia
-- page=Module:Widget/Table2/CellHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Table2ColumnContext = Lua.import('Module:Widget/Table2/ColumnContext')
local ColumnUtil = Lua.import('Module:Widget/Table2/ColumnUtil')

---@class Table2CellHeaderProps
---@field children (Widget|Html|string|number|nil)[]?
---@field align ('left'|'right'|'center')?
---@field shrink (string|number|boolean)?
---@field nowrap (string|number|boolean)?
---@field width string?
---@field minWidth string?
---@field maxWidth string?
---@field unsortable (string|number|boolean)?
---@field sortType string?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?
---@field colspan integer|string?
---@field rowspan integer|string?
---@field columnIndex integer|string?

---@class Table2CellHeader: Widget
---@operator call(Table2CellHeaderProps): Table2CellHeader
---@field props Table2CellHeaderProps
local Table2CellHeader = Class.new(Widget)

---@return Widget
function Table2CellHeader:render()
	local props = self.props

	local columnContext = self:useContext(Table2ColumnContext)

	-- Skip context lookups and property merging if there are no column definitions
	if not columnContext or not columnContext.columns then
		local classes = {'table2__cell--left'}
		if Logic.readBool(props.unsortable) then
			classes = WidgetUtil.collect(classes, 'unsortable')
		end

		return HtmlWidgets.Th{
			classes = WidgetUtil.collect('table2__cell', classes),
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

	local classes = mergedProps.classes
	if Logic.readBool(mergedProps.unsortable) then
		classes = WidgetUtil.collect(classes, 'unsortable')
	end

	local attributes = ColumnUtil.buildAttributes(mergedProps, {
		sortType = function(attrs, cellProps)
			if cellProps.sortType then
				attrs['data-sort-type'] = cellProps.sortType
			end
		end,
	})

	local css = ColumnUtil.buildCss(mergedProps.width, mergedProps.minWidth, mergedProps.maxWidth, mergedProps.css)

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
