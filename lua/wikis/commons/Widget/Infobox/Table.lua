---
-- @Liquipedia
-- page=Module:Widget/Infobox/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class InfoboxTableWidgetWidgetOptions
---@field columns number?
---@field makeLink boolean?
---@field suppressColon boolean?
---@field separator Widget|string|Html|nil

---@class InfoboxTableWidget: Widget
---@operator call(table):InfoboxTableWidget
local InfoboxTableWidget = Class.new(Widget)
InfoboxTableWidget.defaultProps = {
	rows = {},
	options = {
		columns = 2,
		columnOptions = {},
	},
}

---@return Widget?
function InfoboxTableWidget:render()
	local rows = self.props.rows
	local options = self.props.options

	if #rows == 0 then
		return
	end

	return Array.map(rows, function(row)
		return HtmlWidgets.Div{
			classes = self.props.classes,
			children = Array.map(Array.range(1, options.columns), function(columnIndex)
				local columnOptions = options.columnOptions[columnIndex] or {}
				return HtmlWidgets.Div{
					classes = columnOptions.classes or {},
					children = row[columnIndex],
				}
			end),
		}
	end)
end

return InfoboxTableWidget
