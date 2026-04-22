---
-- @Liquipedia
-- page=Module:Components/Table2/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Component = Lua.import('Module:Components/Component')
local Context = Lua.import('Module:Components/Context')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Components/Html')
local Table2Contexts = Lua.import('Module:Components/Contexts/Table2')

---@class Table2ColumnDef
---@field align 'left'|'right'|'center'?
---@field shrink (string|number|boolean)?
---@field nowrap (string|number|boolean)?
---@field width string?
---@field minWidth string?
---@field maxWidth string?
---@field sortType string?
---@field unsortable (string|number|boolean)?
---@field css {[string]: string|number|nil}?
---@field classes string[]?
---@field attributes {[string]: any}?

---@class Table2Props
---@field children Renderable[]?
---@field variant 'generic'|'themed'?
---@field sortable (string|number|boolean)?
---@field striped (string|number|boolean)?
---@field caption Renderable|Renderable[]?
---@field title Renderable|Renderable[]?
---@field footer Renderable|Renderable[]?
---@field classes string[]?
---@field tableClasses string[]?
---@field columns Table2ColumnDef[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?
---@field tableAttributes {[string]: any}?

---@param props Table2Props
---@param context Context
---@return Renderable[]
local function Table2(props, context)
	if props.columns and #props.columns > 0 then
		Array.forEach(props.columns, function(columnDef, columnIndex)
			assert(not (Logic.readBool(columnDef.shrink) and columnDef.width),
				'Table2: Column ' .. columnIndex .. ' - Column definition cannot have both shrink and width properties')
		end)
	end

	local variant = props.variant
	local wrapperClasses = WidgetUtil.collect('table2', 'table2--' .. variant, props.classes)

	local tableClasses = WidgetUtil.collect(
		'table2__table',
		Logic.readBool(props.sortable) and 'sortable' or nil,
		props.tableClasses
	)

	local captionNode = props.caption and Html.Div{
		classes = {'table2__caption'},
		children = props.caption,
	} or nil

	local titleNode = props.title and Html.Div{
		classes = {'table2__title'},
		children = props.title,
	} or nil

	local tableChildren = props.children
	if props.columns and #props.columns > 0 then
		tableChildren = {Context.Provider{
			def = Table2Contexts.ColumnContext,
			value = props.columns,
			children = tableChildren,
		}}
	end

	if Logic.readBool(props.striped) then
		tableChildren = {Context.Provider{
			def = Table2Contexts.BodyStripe,
			value = true,
			children = tableChildren,
		}}
	end

	local tableNode = Html.Table{
		attributes = props.tableAttributes,
		classes = tableClasses,
		children = tableChildren,
	}

	local containerNode = Html.Div{
		classes = {'table2__container'},
		children = {tableNode},
	}

	local footerNode = props.footer and Html.Div{
		classes = {'table2__footer'},
		children = props.footer,
	} or nil

	local tableWrapperNode = Html.Div{
		classes = wrapperClasses,
		css = props.css,
		attributes = props.attributes,
		children = WidgetUtil.collect(titleNode, containerNode, footerNode),
	}

	return WidgetUtil.collect(captionNode, tableWrapperNode)
end

return Component.component(
	Table2,
	{
		variant = 'generic',
		sortable = false,
		striped = true,
		classes = {},
		columns = {},
	}
)
