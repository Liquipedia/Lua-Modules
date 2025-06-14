---
-- @Liquipedia
-- page=Module:Widget/Basic/DataTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Table = HtmlWidgets.Table

---@class WidgetDataTable: Widget
local DataTable = Class.new(Widget)
DataTable.defaultProps = {
	classes = {},
	wrapperClasses = {},
	sortable = false,
}

---@return Widget
function DataTable:render()
	local isSortable = Logic.readBool(self.props.sortable)
	return Div{
		children = {
			Table{
				children = self.props.children,
				classes = WidgetUtil.collect('wikitable', isSortable and 'sortable' or nil, self.props.classes),
				css = self.props.tableCss,
				attributes = self.props.tableAttributes,
			},
		},
		classes = WidgetUtil.collect('table-responsive', self.props.wrapperClasses),
		attributes = self.props.attributes,
	}
end

return DataTable
