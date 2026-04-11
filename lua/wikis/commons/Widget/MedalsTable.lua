---
-- @Liquipedia
-- page=Module:Widget/MedalsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Medals = Lua.import('Module:Medals')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Utils')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DATA_COLUMNS = {'1', '2', '3', '3-4', '4', 'total'}

---@class MedalsTable: Widget
---@operator call(table): MedalsTable
---@field props {caption: string?, footer: Renderable?, data: table}
local MedalsTable = Class.new(Widget)

---@return Widget
function MedalsTable:render()
	return TableWidgets.Table{
		caption = self.props.caption,
		sortable = true,
		columns = WidgetUtil.collect(
			{align = 'left'}, -- tier
			Array.map(DATA_COLUMNS, function() return {align = 'right'} end)
		),
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = WidgetUtil.collect(
						TableWidgets.CellHeader{children = 'Tier'},
						Array.map(DATA_COLUMNS, MedalsTable._headerCell)
					)
				}
			},
			TableWidgets.TableBody{children = self:_rows()}
		},
		footer = self.props.footer
	}
end

---@private
---@param dataColumn string
---@return Widget
function MedalsTable._headerCell(dataColumn)
	return TableWidgets.CellHeader{
		children = dataColumn == 'total' and 'Total' or Medals.display{medal = dataColumn}
	}
end

---@private
---@return Widget[]
function MedalsTable:_rows()
	local totalRowDataSet = Table.extract(self.props.data, 'total')
	local rows = {}

	for tier, dataSet in Table.iter.spairs(self.props.data) do
		table.insert(rows, self:_row(Tier.display(tier, nil, {link = true}), dataSet))
	end
	table.insert(rows, self:_row('Total', totalRowDataSet))

	return rows
end

---@private
---@param firstCellContent Renderable[]|Renderable?
---@param data table<string|integer, integer>
---@return Widget[]
function MedalsTable:_row(firstCellContent, data)
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = firstCellContent},
			Array.map(DATA_COLUMNS, function(column)
				return TableWidgets.Cell{children = data[tonumber(column) or column]}
			end)
		)
	}
end

return MedalsTable
