---
-- @Liquipedia
-- page=Module:Widget/Table2/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2CellProps
---@field children (Widget|Html|string|number|nil)[]?
---@field align ('left'|'right'|'center')?
---@field nowrap (string|number|boolean)?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field attributes {[string]: any}?

---@class Table2Cell: Widget
---@operator call(Table2CellProps): Table2Cell
local Table2Cell = Class.new(Widget)

Table2Cell.defaultProps = {
	classes = {},
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
function Table2Cell:render()
	local props = self.props

	return HtmlWidgets.Td{
		classes = WidgetUtil.collect(
			'table2__cell',
			alignClass(props.align),
			Logic.readBool(props.nowrap) and 'table2__cell--nowrap' or nil,
			props.classes
		),
		css = props.css,
		attributes = props.attributes,
		children = props.children,
	}
end

return Table2Cell
