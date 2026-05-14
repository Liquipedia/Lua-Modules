---
-- @Liquipedia
-- page=Module:Widget/MedalsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Medals = Lua.import('Module:Medals')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Utils')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@generic K, V
---@class MedalsTableProps
---@field caption string?
---@field footer Renderable?
---@field data table<string|table, table<string|integer, integer>>
---@field medalsTableType string?
---@field dataColumns (string|integer)[]?
---@field renderRowFirstCell? fun(key: string|table): Renderable?
---@field rowSort? fun(tbl: {[K]: V}, a: K, b: K):boolean
---@field reducePadding boolean?
---@field hideTotalRow boolean?
---@field cutAfter integer?

local DEFAULT_DATA_COLUMNS = {'1', '2', '3', '3-4', '4', 'total'}

local MedalsTable = {}
MedalsTable.defaultProps = {
	medalsTableType = 'Tier',
	renderRowFirstCell = function(tier)
		return Tier.display(tier, nil, {link = true})
	end,
}

---@param props MedalsTableProps
---@return VNode
function MedalsTable.render(props)
	-- can not use defaultProps as the deepmerge might add unwanted columns from default into the inputted data ...
	local dataColumns = props.dataColumns or DEFAULT_DATA_COLUMNS

	local collapsed = Logic.isNotEmpty(props.cutAfter)

	return TableWidgets.Table{
		caption = props.caption,
		sortable = not collapsed,
		tableClasses = collapsed and {'prizepooltable', 'collapsed'} or nil,
		tableAttributes = collapsed and {
			['data-opentext'] = 'Show more',
			['data-closetext'] = 'Show less',
			['data-cutafter'] = props.cutAfter,
		} or nil,
		columns = WidgetUtil.collect(
			{align = 'left'}, -- tier
			Array.map(dataColumns, function() return {align = 'right'} end)
		),
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = WidgetUtil.collect(
						TableWidgets.CellHeader{
							children = props.medalsTableType,
							css = props.reducePadding and {['padding-left'] = '0.3rem'} or nil,
						},
						Array.map(dataColumns, FnUtil.curry(MedalsTable._headerCell, props))
					)
				}
			},
			TableWidgets.TableBody{children = MedalsTable._rows(props, dataColumns)}
		},
		footer = props.footer
	}
end

---@private
---@param props MedalsTableProps
---@param dataColumn string
---@return VNode
function MedalsTable._headerCell(props, dataColumn)
	---@type Renderable?
	local header
	if dataColumn == 'total' then
		header = 'Total'
	elseif dataColumn == 'top3' then
		header = Html.Abbr{title = 'Total of top 3', children = 'Top3'}
	else
		header = Medals.display{medal = dataColumn}
	end

	return TableWidgets.CellHeader{
		css = props.reducePadding and {['padding-left'] = '0.3rem'} or nil,
		children = header
	}
end

---@private
---@param props MedalsTableProps
---@param dataColumns (string|integer)[]
---@return VNode[]
function MedalsTable._rows(props, dataColumns)
	local totalRowDataSet = Table.extract(props.data, 'total')
	local rows = {}

	for key, dataSet in Table.iter.spairs(props.data, props.rowSort) do
		table.insert(rows, MedalsTable._row(props.renderRowFirstCell(key), dataSet, dataColumns))
	end
	if props.hideTotalRow then
		return rows
	end

	table.insert(rows, MedalsTable._row('Total', totalRowDataSet, dataColumns))

	return rows
end

---@private
---@param firstCellContent Renderable[]|Renderable?
---@param data table<string|integer, integer>
---@param dataColumns (string|integer)[]
---@return VNode[]
function MedalsTable._row(firstCellContent, data, dataColumns)
	local dashIfZero = function(input)
		if not input or input == 0 then
			return '-'
		end
		return input
	end
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = firstCellContent},
			Array.map(dataColumns, function(column)
				return TableWidgets.Cell{children = dashIfZero(data[tonumber(column) or column])}
			end)
		)
	}
end

return Component.component(MedalsTable.render, MedalsTable.defaultProps)
