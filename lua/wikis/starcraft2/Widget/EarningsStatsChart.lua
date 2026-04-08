---
-- @Liquipedia
-- page=Module:Widget/EarningsStatsChart
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Widget = Lua.import('Module:Widget')

---@class EarningsStatsChart: Widget
---@operator call(table): EarningsStatsChart
---@field props {dataPoints: {legend: string, key: string}[], data: table}
local EarningsStatsChart = Class.new(Widget)

---@return Widget?
function EarningsStatsChart:render()
	local data, years = self:_parse()
	if Logic.isEmpty(data) then
		return
	end

	return HtmlWidgets.Div{
		classes = {'table-responsive'},
		children = {
			HtmlWidgets.H3{children = 'Earnings Statistics'},
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
				legend = Array.map(self.props.dataPoints, Operator.property('legend')),
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

---@return {data: number[], emphasis: {focus: string}, name: string, stack: string, type: string}[]?
---@return integer[]?
function EarningsStatsChart:_parse()
	local dataSets = Array.map(self.props.dataPoints, function(dataPoint)
		return self.props.data[dataPoint.key] or {}
	end)

	---@param year integer
	---@return boolean
	local hasAnyPositiveValue = function(year)
		return Array.any(dataSets, function(dataSet)
			return (dataSet[year] or 0) > 0
		end)
	end

	local currentYear = tonumber(DateExt.formatTimestamp('Y', DateExt.getCurrentTimestamp())) --[[@as integer]]
	local years = Array.filter(Array.range(Info.startYear, currentYear), function(year)
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

	local chartData = Array.map(self.props.dataPoints, function(dataPoint, index)
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

return EarningsStatsChart
