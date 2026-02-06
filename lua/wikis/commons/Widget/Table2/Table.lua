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
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?
---@field sortable (string|number|boolean)?
---@field variant ('generic'|'themed')?
---@field variants ('generic'|'themed')?
---@field modifiers string[]?
---@field wrapperClasses string[]?
---@field wrapperCss {[string]: string|number|nil}?
---@field wrapperAttributes {[string]: any}?
---@field tableClasses string[]?
---@field tableCss {[string]: string|number|nil}?
---@field tableAttributes {[string]: any}?
---@field caption (Widget|Html|string|number)?
---@field footer (Widget|Html|string|number)?

---@class Table2: Widget
---@operator call(Table2Props): Table2
local Table2 = Class.new(Widget)

Table2.defaultProps = {
	classes = {},
	variant = 'generic',
	modifiers = {},
	sortable = false,
	wrapperClasses = {},
	tableClasses = {},
}

---@return Widget
function Table2:render()
	local wrapperClasses = WidgetUtil.collect('table2', self.props.classes, self.props.wrapperClasses)
	local wrapperCss = self.props.wrapperCss or self.props.css
	local wrapperAttributes = self.props.wrapperAttributes or self.props.attributes

	local variant = self.props.variant or self.props.variants or 'generic'
	table.insert(wrapperClasses, 'table2--' .. variant)

	for _, modifier in ipairs(self.props.modifiers or {}) do
		if modifier ~= 'themed' and modifier ~= 'generic' then
			table.insert(wrapperClasses, 'table2--' .. modifier)
		end
	end

	local tableClasses = WidgetUtil.collect(
		'table2__table',
		Logic.readBool(self.props.sortable) and 'sortable' or nil,
		self.props.tableClasses
	)

	local captionNode = self.props.caption and HtmlWidgets.Div{
		classes = {'table2__caption'},
		children = {self.props.caption},
	} or nil

	local tableNode = HtmlWidgets.Table{
		classes = tableClasses,
		css = self.props.tableCss,
		attributes = self.props.tableAttributes,
		children = self.props.children
	}

	local content = HtmlWidgets.Div{
		classes = {'table2__scroll'},
		children = {tableNode},
	}

	local footer = self.props.footer and HtmlWidgets.Div{
		classes = {'table2__footer'},
		children = {self.props.footer},
	} or nil

	return HtmlWidgets.Div{
		classes = wrapperClasses,
		css = wrapperCss,
		attributes = wrapperAttributes,
		children = WidgetUtil.collect(captionNode, content, footer),
	}
end

return Table2
