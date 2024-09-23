---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/DataTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Table = HtmlWidgets.Table

---@class WidgetDataTable: Widget
local DataTable = Class.new(Widget)

---@return Widget
function DataTable:render()
	return Div{
		children = {
			Table{
				children = self.props.children,
				classes = {'wikitable', unpack(self.props.classes or {})}
			},
		},
		classes = {'table-responsive'},
	}
end

return DataTable
