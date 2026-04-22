---
-- @Liquipedia
-- page=Module:Components/Table2/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Components/Component')
local Context = Lua.import('Module:Components/Context')

local Html = Lua.import('Module:Components/Html')
local Table2Contexts = Lua.import('Module:Components/Contexts/Table2')
local ColumnUtil = Lua.import('Module:Components/Table2/ColumnUtil')

---@class Table2CellProps
---@field children Renderable[]?
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

---@param props Table2CellProps
---@return Renderable
local function Table2Cell(props, context)
	local columns = Context.read(context, Table2Contexts.ColumnContext)

	-- Skip context lookups and property merging if there are no column definitions
	if not columns then
		return Html.Td{
			attributes = ColumnUtil.buildCellAttributes(
				props.align,
				props.nowrap,
				props.shrink,
				props.attributes
			),
			classes = props.classes,
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

	return Html.Td{
		classes = mergedProps.classes,
		css = css,
		attributes = attributes,
		children = mergedProps.children,
	}
end

return Component.component(
	Table2Cell,
	{
		nowrap = true,
	}
)
