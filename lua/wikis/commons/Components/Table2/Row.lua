---
-- @Liquipedia
-- page=Module:Components/Table2/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Component = Lua.import('Module:Components/Component')
local Context = Lua.import('Module:Components/Context')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')

local Table2Contexts = Lua.import('Module:Components/Contexts/Table2')
local Table2Cell = Lua.import('Module:Components/Table2/Cell')
local Table2CellHeader = Lua.import('Module:Components/Table2/CellHeader')
local Table2CellHeaderMT = getmetatable(Table2CellHeader)
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Components/Html')

---@class Table2RowProps
---@field children Renderable[]?
---@field section 'head'|'body'|'subhead'?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?
---@field highlighted (string|number|boolean)?

---@param props Table2RowProps
---@param context Context
---@return Renderable
local function Table2Row(props, context)
	local section = props.section or Context.read(context, Table2Contexts.Section)
	local headerRowKind = Context.read(context, Table2Contexts.HeaderRowKind)
	local bodyStripe = Context.read(context, Table2Contexts.BodyStripe)

	local sectionClass = 'table2__row--body'
	if section == 'head' or section == 'subhead' then
		sectionClass = 'table2__row--head'
	end

	local kindClass
	if section == 'head' then
		if headerRowKind == 'title' then
			kindClass = 'table2__row--head-title'
		elseif headerRowKind == 'columns' then
			kindClass = 'table2__row--head-columns'
		end
	end

	local stripeClass
	if section == 'body' then
		if bodyStripe == 'odd' then
			stripeClass = 'table2__row--odd'
		elseif bodyStripe == 'even' then
			stripeClass = 'table2__row--even'
		end
	end

	local highlightClass
	if section == 'body' and Logic.readBool(props.highlighted) then
		highlightClass = 'table2__row--highlighted'
	end

	local children = props.children or {}

	local columns = Context.read(context, Table2Contexts.ColumnContext)
	if section == 'subhead' and columns and #children == 1 and getmetatable(children[1]) == Table2CellHeaderMT then
		local singleCell = children[1] --[[@as Table2CellHeader]]
		if singleCell.props.colspan == nil then
			singleCell.props.colspan = #columns
		end
	end

	local columnIndex = 1
	local indexedChildren = Array.map(children, function(child)
		if getmetatable(child) == getmetatable(Table2Cell) or getmetatable(child) == Table2CellHeaderMT then
			local cellChild = child --[[@as Table2Cell|Table2CellHeader]]
			local explicitIndex = MathUtil.toInteger(cellChild.props.columnIndex)
			if explicitIndex and explicitIndex >= 1 then
				columnIndex = math.max(columnIndex, explicitIndex)
			elseif cellChild.props.columnIndex == nil then
				cellChild.props.columnIndex = columnIndex
			end

			local span = MathUtil.toInteger(cellChild.props.colspan) or 1
			if span < 1 then
				span = 1
			end
			columnIndex = columnIndex + span
			return cellChild
		end
		return child
	end)

	local trChildren = indexedChildren
	if section == 'subhead' then
		trChildren = Array.map(trChildren, function(child)
			if getmetatable(child) == Table2CellHeaderMT then
				return Context.Provider{
					def = Table2Contexts.Section,
					value = 'subhead',
					children = {child},
				}
			end
			return child
		end)
	end

	return Html.Tr{
		classes = WidgetUtil.collect(sectionClass, kindClass, stripeClass, highlightClass, props.classes),
		css = props.css,
		attributes = props.attributes,
		children = trChildren,
	}
end

return Component.component(
	Table2Row
)
