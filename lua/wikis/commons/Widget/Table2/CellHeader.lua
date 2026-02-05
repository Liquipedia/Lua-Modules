---
-- @Liquipedia
-- page=Module:Widget/Table2/CellHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2CellHeaderProps
---@field children (Widget|Html|string|number|nil)[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?
---@field align ('left'|'right'|'center')?
---@field nowrap (string|number|boolean)?
---@field unsortable (string|number|boolean)?
---@field sortType string?
---@field colspan integer?
---@field rowspan integer?

---@class Table2CellHeader: Widget
---@operator call(Table2CellHeaderProps): Table2CellHeader
local Table2CellHeader = Class.new(Widget)

Table2CellHeader.defaultProps = {
	classes = {},
	attributes = {},
}

---@return string
local function alignClass(align)
	if align == 'right' then
		return 'table2__cell--right'
	elseif align == 'center' then
		return 'table2__cell--center'
	end
	return 'table2__cell--left'
end

---@return Widget
function Table2CellHeader:render()
	local classes = self.props.classes
	if Logic.readBool(self.props.unsortable) then
		-- MediaWiki sortable tables skip headers with this class
		classes = WidgetUtil.collect(classes, 'unsortable')
	end

	local attributes = Table.copy(self.props.attributes or {})
	if self.props.sortType ~= nil then
		attributes['data-sort-type'] = self.props.sortType
	end
	if self.props.colspan ~= nil then
		attributes.colspan = self.props.colspan
	end
	if self.props.rowspan ~= nil then
		attributes.rowspan = self.props.rowspan
	end

	return HtmlWidgets.Th{
		classes = WidgetUtil.collect(
			'table2__cell',
			alignClass(self.props.align),
			Logic.readBool(self.props.nowrap) and 'table2__cell--nowrap' or nil,
			classes
		),
		css = self.props.css,
		attributes = attributes,
		children = self.props.children,
	}
end

return Table2CellHeader
