---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Basic/DataTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
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
}

---@return Widget
function DataTable:render()
	return Div{
		children = {
			Table{
				children = self.props.children,
				classes = WidgetUtil.collect('wikitable', unpack(self.props.classes)),
			},
		},
		classes = WidgetUtil.collect('table-responsive', unpack(self.props.wrapperClasses)),
		attributes = self.props.attributes,
	}
end

return DataTable
