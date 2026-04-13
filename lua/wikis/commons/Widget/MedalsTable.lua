---
-- @Liquipedia
-- page=Module:Widget/MedalsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Medals = Lua.import('Module:Medals')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Utils')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DATA_COLUMNS_VARIANT_1 = {'1', '2', '3', '3-4', '4', 'total'}
local DATA_COLUMNS_VARIANT_2 = {1, 2, 3, 'top3', 'total'}

---@class MedalsTableProps
---@field caption string?
---@field footer Renderable?
---@field data table<string, table<string, integer>> # table<tier, table<place, integer>>
---@field hasAll boolean?

---@class MedalsTable: Widget
---@operator call(MedalsTableProps): MedalsTable
---@field props MedalsTableProps
---@field dataColumns string[]
local MedalsTable = Class.new(Widget)

---@return Widget
function MedalsTable:render()
	self.dataColumns = self.props.hasAll and DATA_COLUMNS_VARIANT_2 or DATA_COLUMNS_VARIANT_1
	return TableWidgets.Table{
		caption = self.props.caption,
		sortable = true,
		columns = WidgetUtil.collect(
			{align = 'left'}, -- tier
			Array.map(self.dataColumns, function() return {align = 'right'} end)
		),
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = WidgetUtil.collect(
						TableWidgets.CellHeader{
							children = 'Tier',
							css = self.props.hasAll and {['padding-left'] = '0.3rem'} or nil,
						},
						Array.map(self.dataColumns, FnUtil.curry(MedalsTable._headerCell, self))
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
function MedalsTable:_headerCell(dataColumn)
	---@type Renderable?
	local header
	if dataColumn == 'total' then
		header = 'Total'
	elseif dataColumn == 'top3' then
		header = HtmlWidgets.Abbr{title = 'Total of top 3', children = 'Top3'}
	else
		header = Medals.display{medal = dataColumn}
	end

	return TableWidgets.CellHeader{
		css = self.props.hasAll and {['padding-left'] = '0.3rem'} or nil,
		children = header
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
			Array.map(self.dataColumns, function(column)
				return TableWidgets.Cell{children = data[tonumber(column) or column]}
			end)
		)
	}
end

return MedalsTable
