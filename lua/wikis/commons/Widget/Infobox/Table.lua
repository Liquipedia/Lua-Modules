---
-- @Liquipedia
-- page=Module:Widget/Infobox/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class InfoboxTableWidgetWidgetOptions
---@field columns number?
---@field columnOptions {classes: string[]?}[]?
---@field makeLink boolean?
---@field suppressColon boolean?
---@field separator Renderable?

---@class InfoboxTableWidgetProps
---@field rows Renderable[][]
---@field options InfoboxTableWidgetWidgetOptions?
---@field classes string[]?

local defaultProps = {
	rows = {},
	options = {
		columns = 2,
		columnOptions = {},
	},
}

---@param props InfoboxTableWidgetProps
---@return Renderable[]?
local function InfoboxTableWidget(props)
	local rows = props.rows
	local options = props.options or {}

	if #rows == 0 then
		return
	end

	return Array.map(rows, function(row)
		return Html.Div{
			classes = props.classes,
			children = Array.mapRange(1, options.columns, function(columnIndex)
				local columnOptions = options.columnOptions[columnIndex] or {}
				return Html.Div{
					classes = columnOptions.classes or {},
					children = row[columnIndex],
				}
			end),
		}
	end)
end

return Component.component(InfoboxTableWidget, defaultProps)
