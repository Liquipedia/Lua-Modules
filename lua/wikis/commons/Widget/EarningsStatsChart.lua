---
-- @Liquipedia
-- page=Module:Widget/EarningsStatsChart
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local EarningsStatsChart = {}

---@param props {dataPoints: {legend: string, key: string}[], data: table}
---@return VNode?
function EarningsStatsChart.render(props)
	local data, years = EarningsStatsChart._parse(props)

	if Logic.isEmpty(data) then
		return
	end

	return Html.Div{
		classes = {'table-responsive'},
		children = {
			Html.H3{children = 'Earnings Statistics'},
			mw.ext.Charts.chart{
				grid = {
					left = '15%',
					right = '12%',
					top = '15%',
					bottom = '10%'
				},
				size = {
					height = 400,
					width = 1400,
				},
				tooltip = {
					trigger = 'axis',
				},
				legend = Array.map(props.dataPoints, Operator.property('legend')),
				xAxis = {
					axisLabel = {rotate = 0},
					axisTick = {alignWithLabel = true},
					data = years,
					name = 'Year',
					type = 'category',
				},
				yAxis = {name = 'Earnings ($USD)', type = 'value'},
				series = data,
			}
		},
	}
end

---@param props {dataPoints: {legend: string, key: string}[], data: table}
---@return {data: number[], emphasis: {focus: string}, name: string, stack: string, type: string}[]?
---@return integer[]?
function EarningsStatsChart._parse(props)
	local dataSets = Array.map(props.dataPoints, function(dataPoint)
		return props.data[dataPoint.key] or {}
	end)

	---@param year integer
	---@return boolean
	local hasAnyPositiveValue = function(year)
		return Array.any(dataSets, function(dataSet)
			return (dataSet[year] or 0) > 0
		end)
	end

	local years = Array.filter(Array.range(Info.startYear, DateExt.getYearOf()), function(year)
		return hasAnyPositiveValue(year - 1) or hasAnyPositiveValue(year) or hasAnyPositiveValue(year + 1)
	end)

	if Logic.isEmpty(years) then
		return
	end

	if not hasAnyPositiveValue(years[1]) then
		table.remove(years, 1)
	end

	if not hasAnyPositiveValue(years[#years]) then
		table.remove(years)
	end

	local chartData = Array.map(props.dataPoints, function(dataPoint, index)
		return {
			data = Array.map(years, function(year) return dataSets[index][year] or 0 end),
			emphasis = {
				focus = 'series',
			},
			name = dataPoint.legend,
			stack = 'total',
			type = 'bar',
		}
	end)

	return chartData, years
end

return Component.component(EarningsStatsChart.render)
