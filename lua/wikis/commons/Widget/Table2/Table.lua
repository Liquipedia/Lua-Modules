---
-- @Liquipedia
-- page=Module:Widget/Table2/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Table2ColumnContext = Lua.import('Module:Widget/Table2/ColumnContext')
local ColumnUtil = Lua.import('Module:Widget/util/ColumnUtil')

---@class Table2ColumnDef
---@field align 'left'|'right'|'center'?
---@field shrink (string|number|boolean)?
---@field nowrap (string|number|boolean)?
---@field width string?
---@field minWidth string?
---@field maxWidth string?
---@field sortType string?
---@field unsortable (string|number|boolean)?
---@field colspan integer?
---@field rowspan integer?
---@field css {[string]: string|number|nil}?
---@field classes string[]?
---@field attributes {[string]: any}?

---@class Table2Props
---@field children (Widget|Html|string|number|nil)[]?
---@field variant 'generic'|'themed'?
---@field sortable (string|number|boolean)?
---@field caption Widget|Html|string|number?
---@field title Widget|Html|string|number?
---@field footer Widget|Html|string|number?
---@field classes string[]?
---@field columns Table2ColumnDef[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2: Widget
---@operator call(Table2Props): Table2
local Table2 = Class.new(Widget)

Table2.defaultProps = {
	variant = 'generic',
	sortable = false,
	classes = {},
	columns = {},
}

---@return Widget
function Table2:render()
	local props = self.props

	if props.columns and #props.columns > 0 then
		Array.forEach(props.columns, function(columnDef, i)
			local valid, errorMsg = ColumnUtil.validateColumnDef(columnDef)
			assert(valid, 'Table2: Column ' .. i .. ' - ' .. errorMsg)
		end)
	end

	local variant = props.variant
	local wrapperClasses = WidgetUtil.collect('table2', 'table2--' .. variant, props.classes)

	local tableClasses = WidgetUtil.collect(
		'table2__table',
		Logic.readBool(props.sortable) and 'sortable' or nil
	)

	local captionNode = props.caption and HtmlWidgets.Div{
		classes = {'table2__caption'},
		children = {props.caption},
	} or nil

	local titleNode = props.title and HtmlWidgets.Div{
		classes = {'table2__title'},
		children = {props.title},
	} or nil

	local tableChildren = props.children
	if props.columns and #props.columns > 0 then
		tableChildren = {Table2ColumnContext{
			columns = props.columns,
			children = props.children,
		}}
	end

	local tableNode = HtmlWidgets.Table{
		classes = tableClasses,
		children = tableChildren,
	}

	local containerNode = HtmlWidgets.Div{
		classes = {'table2__container'},
		children = {tableNode},
	}

	local footerNode = props.footer and HtmlWidgets.Div{
		classes = {'table2__footer'},
		children = {props.footer},
	} or nil

	local tableWrapperNode = HtmlWidgets.Div{
		classes = wrapperClasses,
		css = props.css,
		attributes = props.attributes,
		children = WidgetUtil.collect(titleNode, containerNode, footerNode),
	}

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(captionNode, tableWrapperNode),
	}
end

return Table2
