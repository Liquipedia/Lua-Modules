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
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')
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

	local columns = self:useContext(Table2Contexts.ColumnContext)

	-- Skip context lookups and property merging if there are no column definitions
	if not columns then
		local attributes = props.attributes or {}
		if Logic.readBool(props.unsortable) then
			attributes.class = 'unsortable'
		end

		attributes = ColumnUtil.buildCellAttributes(
			props.align,
			props.nowrap,
			props.shrink,
			attributes
		)

		return HtmlWidgets.Th{
			attributes = attributes,
			children = props.children,
		}
	end

	local columnDef
	local columnIndex = ColumnUtil.getColumnIndex(props.columnIndex, nil)

	if columns[columnIndex] then
		columnDef = columns[columnIndex]
	end

	local mergedProps = ColumnUtil.mergeProps(props, columnDef)

	local attributes = ColumnUtil.buildAttributes(mergedProps, {
		sortType = function(attrs, cellProps)
			if cellProps.sortType then
				attrs['data-sort-type'] = cellProps.sortType
			end
		end,
	})

	if Logic.readBool(mergedProps.unsortable) then
		attributes.class = 'unsortable'
	end

	local css = ColumnUtil.buildCss(mergedProps.width, mergedProps.minWidth, mergedProps.maxWidth, mergedProps.css)

	attributes = ColumnUtil.buildCellAttributes(
		mergedProps.align,
		mergedProps.nowrap,
		mergedProps.shrink,
		attributes
	)

	return HtmlWidgets.Th{
		classes = mergedProps.classes,
		css = css,
		attributes = attributes,
		children = mergedProps.children,
	}
end

return Table2CellHeader
