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
local Logic = Lua.import('Module:Logic')
local Medals = Lua.import('Module:Medals')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Utils')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@generic K, V
---@class MedalsTableProps
---@field caption string?
---@field footer Renderable?
---@field data table<string|table, table<string|integer, integer>>
---@field medalsTableType string
---@field dataColumns (string|integer)[]?
---@field renderRowFirstCell fun(key: string|table): Renderable?
---@field rowSort? fun(tbl: {[K]: V}, a: K, b: K):boolean
---@field reducePadding boolean?
---@field hideTotalRow boolean?
---@field cutAfter integer?

local DEFAULT_DATA_COLUMNS = {'1', '2', '3', '3-4', '4', 'total'}

---@class MedalsTable: Widget
---@operator call(MedalsTableProps): MedalsTable
---@field props MedalsTableProps
---@field dataColumns (integer|string)[]
local MedalsTable = Class.new(Widget)
MedalsTable.defaultProps = {
	medalsTableType = 'Tier',
	renderRowFirstCell = function(tier)
		return Tier.display(tier, nil, {link = true})
	end,
}

---@return Widget
function MedalsTable:render()
	-- can not use defaultProps as the deepmerge might add unwanted columns from default into the inputted data ...
	self.dataColumns = self.props.dataColumns or DEFAULT_DATA_COLUMNS

	local collapsed = Logic.isNotEmpty(self.props.cutAfter)

	return TableWidgets.Table{
		caption = self.props.caption,
		sortable = not collapsed,
		tableClasses = collapsed and {'prizepooltable', 'collapsed'} or nil,
		tableAttributes = collapsed and {
			['data-opentext'] = 'Show more',
			['data-closetext'] = 'Show less',
			['data-cutafter'] = self.props.cutAfter,
		} or nil,
		columns = WidgetUtil.collect(
			{align = 'left'}, -- tier
			Array.map(self.dataColumns, function() return {align = 'right'} end)
		),
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = WidgetUtil.collect(
						TableWidgets.CellHeader{
							children = self.props.medalsTableType,
							css = self.props.reducePadding and {['padding-left'] = '0.3rem'} or nil,
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
		css = self.props.reducePadding and {['padding-left'] = '0.3rem'} or nil,
		children = header
	}
end

---@private
---@return Widget[]
function MedalsTable:_rows()
	local totalRowDataSet = Table.extract(self.props.data, 'total')
	local rows = {}

	for key, dataSet in Table.iter.spairs(self.props.data, self.props.rowSort) do
		table.insert(rows, self:_row(self.props.renderRowFirstCell(key), dataSet))
	end
	if self.props.hideTotalRow then
		return rows
	end

	table.insert(rows, self:_row('Total', totalRowDataSet))

	return rows
end

---@private
---@param firstCellContent Renderable[]|Renderable?
---@param data table<string|integer, integer>
---@return Widget[]
function MedalsTable:_row(firstCellContent, data)
	local dashIfZero = function(input)
		if not input or input == 0 then
			return '-'
		end
		return input
	end
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = firstCellContent},
			Array.map(self.dataColumns, function(column)
				return TableWidgets.Cell{children = dashIfZero(data[tonumber(column) or column])}
			end)
		)
	}
end

return MedalsTable
