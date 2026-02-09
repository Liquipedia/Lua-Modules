---
-- @Liquipedia
-- page=Module:Widget/Table2/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2Props
---@field children (Widget|Html|string|number|nil)[]?
---@field variant 'generic'|'themed'?
---@field sortable (string|number|boolean)?
---@field caption Widget|Html|string|number?
---@field title Widget|Html|string|number?
---@field footer Widget|Html|string|number?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2: Widget
---@operator call(Table2Props): Table2
local Table2 = Class.new(Widget)

Table2.defaultProps = {
	variant = 'generic',
	sortable = false,
	classes = {},
}

---@return Widget
function Table2:render()
	local props = self.props

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

	local tableNode = HtmlWidgets.Table{
		classes = tableClasses,
		children = props.children,
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
