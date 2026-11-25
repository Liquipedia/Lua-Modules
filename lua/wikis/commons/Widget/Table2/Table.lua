---
-- @Liquipedia
-- page=Module:Widget/Table2/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Component = Lua.import('Module:Widget/Component')
local Context = Lua.import('Module:Widget/ComponentContext')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local LabeledChevronToggle = Lua.import('Module:Widget/GeneralCollapsible/LabeledChevronToggle')
local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')

---@class Table2ColumnDef
---@field align 'left'|'right'|'center'?
---@field shrink (string|number|boolean)?
---@field nowrap (string|number|boolean)?
---@field width string?
---@field minWidth string?
---@field maxWidth string?
---@field sortType string?
---@field unsortable (string|number|boolean)?
---@field css HtmlStyleProps?
---@field classes string[]?
---@field attributes {[string]: any}?

---@class Table2Props: HtmlNodeProps
---@field variant 'generic'|'themed'?
---@field sortable (string|number|boolean)?
---@field striped (string|number|boolean)?
---@field caption Renderable|Renderable[]?
---@field title Renderable|Renderable[]?
---@field footer Renderable|Renderable[]?
---@field tableClasses string[]?
---@field columns Table2ColumnDef[]?
---@field tableAttributes {[string]: any}?
---@field collapseAfter integer? # Collapses the rows of each body past this behind a footer toggle
---@field expandText Renderable?
---@field collapseText Renderable?

---@param props Table2Props
---@param context Context
---@return Renderable[]
local function Table2(props, context)
	local tableChildren = props.children
	---@cast tableChildren Renderable[]

	if props.columns and #props.columns > 0 then
		Array.forEach(props.columns, function(columnDef, columnIndex)
			assert(not (Logic.readBool(columnDef.shrink) and columnDef.width),
				'Table2: Column ' .. columnIndex .. ' - Column definition cannot have both shrink and width properties')
		end)
	end

	local variant = props.variant
	local collapseAfter = props.collapseAfter
	local wrapperClasses = WidgetUtil.collect(
		'table2',
		'table2--' .. variant,
		props.classes,
		collapseAfter and 'general-collapsible' or nil,
		collapseAfter and 'collapsed' or nil
	)

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

	if props.columns and #props.columns > 0 then
		tableChildren = {Context.Provider{
			def = Table2Contexts.ColumnContext,
			value = props.columns,
			children = tableChildren,
		}}
	end

	-- Always provided, so nested tables do not inherit them
	tableChildren = {Context.Provider{
		def = Table2Contexts.CollapseAfter,
		value = collapseAfter,
		children = {Context.Provider{
			def = Table2Contexts.CollapseCounter,
			value = nil,
			children = tableChildren,
		}},
	}}

	local tableAttributes = props.tableAttributes or {}
	if not Logic.readBool(props.striped) then
		tableAttributes['data-striped'] = 'false'
	end

	local tableNode = Html.Table{
		attributes = tableAttributes,
		classes = tableClasses,
		children = tableChildren,
	}

	local containerNode = Html.Div{
		classes = {'table2__container'},
		children = {tableNode},
	}

	local collapseToggle = collapseAfter and Html.Div{
		classes = {'table2__collapse-toggle'},
		attributes = {['data-collapsible-click-region'] = 'true'},
		children = LabeledChevronToggle{
			expandText = props.expandText or 'Show more',
			collapseText = props.collapseText or 'Show less',
		},
	} or nil

	local footerNode = (props.footer or collapseToggle) and Html.Div{
		classes = {'table2__footer'},
		children = WidgetUtil.collect(props.footer, collapseToggle),
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
