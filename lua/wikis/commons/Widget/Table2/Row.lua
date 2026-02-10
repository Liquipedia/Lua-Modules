---
-- @Liquipedia
-- page=Module:Widget/Table2/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Table2Section = Lua.import('Module:Widget/Table2/Section')
local Table2HeaderRowKind = Lua.import('Module:Widget/Table2/HeaderRowKind')
local Table2BodyStripe = Lua.import('Module:Widget/Table2/BodyStripe')
local Table2CellIndexer = Lua.import('Module:Widget/Table2/CellIndexer')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2RowProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Row: Widget
---@operator call(Table2RowProps): Table2Row
local Table2Row = Class.new(Widget)
Table2Row.defaultProps = {
	classes = {},
}

---@return Widget
function Table2Row:render()
	local props = self.props
	local section = self:useContext(Table2Section)
	local headerRowKind = self:useContext(Table2HeaderRowKind)
	local bodyStripe = self:useContext(Table2BodyStripe)

	local sectionClass = 'table2__row--body'
	if section == 'head' then
		sectionClass = 'table2__row--head'
	end

	local kindClass = nil
	if section == 'head' then
		if headerRowKind == 'title' then
			kindClass = 'table2__row--head-title'
		elseif headerRowKind == 'columns' then
			kindClass = 'table2__row--head-columns'
		end
	end

	local stripeClass = nil
	if section == 'body' then
		if bodyStripe == 'odd' then
			stripeClass = 'table2__row--odd'
		elseif bodyStripe == 'even' then
			stripeClass = 'table2__row--even'
		end
	end

	local indexedChildren = {Table2CellIndexer{
		children = props.children,
	}}

	return HtmlWidgets.Tr{
		classes = WidgetUtil.collect('table2__row', sectionClass, kindClass, stripeClass, props.classes),
		css = props.css,
		attributes = props.attributes,
		children = indexedChildren,
	}
end

return Table2Row
