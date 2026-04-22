---
-- @Liquipedia
-- page=Module:Components/Table2/CellHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Components/Component')
local Context = Lua.import('Module:Components/Context')

local Logic = Lua.import('Module:Logic')

local Html = Lua.import('Module:Components/Html')
local Table2Contexts = Lua.import('Module:Components/Contexts/Table2')
local ColumnUtil = Lua.import('Module:Components/Table2/ColumnUtil')

---@class Table2CellHeaderProps
---@field children Renderable[]?
---@field section 'head'|'body'|'subhead'?
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

---@param props Table2CellHeaderProps
---@return Renderable
local function Table2CellHeader(props, context)
	local columns = Context.read(context, Table2Contexts.ColumnContext)
	local section = props.section or Context.read(context, Table2Contexts.Section)

	local children = props.children
	if section == 'subhead' then
		children = {Html.Div{
			classes = {'table2__subheader-cell'},
			children = props.children,
		}}
	end

	-- Skip context lookups and property merging if there are no column definitions
	if not columns then
		local align = props.align
		local attributes = props.attributes or {}
		if align == 'right' or align == 'center' then
			attributes['data-align'] = align
		end
		if Logic.readBool(props.unsortable) then
			attributes.class = 'unsortable'
		end

		attributes = ColumnUtil.buildCellAttributes(
			props.align,
			props.nowrap,
			props.shrink,
			attributes
		)

		return Html.Th{
			attributes = attributes,
			children = children,
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

	return Html.Th{
		classes = mergedProps.classes,
		css = css,
		attributes = attributes,
		children = children,
	}
end

return Component.component(
	Table2CellHeader
)
