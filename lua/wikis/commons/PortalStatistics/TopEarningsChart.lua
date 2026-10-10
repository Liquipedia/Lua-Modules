---
-- @Liquipedia
-- page=Module:PortalStatistics/TopEarningsChart
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Opponent = Lua.import('Module:Opponent/Custom')
local Html = Lua.import('Module:Widget/Html')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CURRENT_YEAR = DateExt.getYearOf()
local MAX_OPPONENT_LIMIT = Info.config.defaultMaxPlayersPerPlacement or 10
local MAX_QUERY_LIMIT = 5000

local StatisticsPortal = {}


---@param args table?
---@return Renderable
function StatisticsPortal.topEarningsChart(args)
	args = args or {}
	args.limit = tonumber(args.limit) or 10
	args.startYear = tonumber(args.year)

	local params = {
		catLabel = Logic.readBool(args.isForTeam) and 'Teams' or 'Players',
		flipAxes = true,
		emphasis = 'none',
	}

	local config = StatisticsPortal._getChartConfig(args, params)
	local topEarningsList = StatisticsPortal._getOpponentEarningsData(args, config)

	local yearSeriesData = Array.mapRange(config.startYear, tonumber(args.year) or CURRENT_YEAR, function(year)
		return Array.map(Array.reverse(topEarningsList), function(teamData)
			return teamData.earningsbyyear[year] or 0
		end)
	end)

	local opponentNames = Array.map(Array.reverse(topEarningsList), function(opponent)
		return config.opponentType == Opponent.team and opponent.name or opponent.id
	end)

	if Logic.readBool(config.yearBreakdown) then
		return StatisticsPortal._buildChartData(config, yearSeriesData, opponentNames)
	else
		local chartData = {}
		chartData[1] = {
			name = 'Total Earnings',
			type = 'bar',
			stack = config.stackType,
			data = StatisticsPortal._addArrays(yearSeriesData),
		}

		config.yAxis = {
			type = 'value',
			name = 'Earnings ($USD)',
		}
		config.xAxis = {
			type = 'category',
			name = config.catLabel,
			data = opponentNames,
			axisTick = {
				alignWithLabel = true,
			},
		}
		config.customLegend = config.customLegend or config.customInputs
		return StatisticsPortal._drawChart(config, chartData)
	end
end


--[[
Section: Coverage Breakdown
]] --

---@param args table
---@param config table
---@return table
function StatisticsPortal._getOpponentEarningsData(args, config)
	local opponentType = config.opponentType == Opponent.team and 'team' or 'player'
	local queryFields
	if opponentType == Opponent.team then
		queryFields = 'pagename, name, template, earnings, earningsbyyear'
	else
		queryFields = 'pagename, id, nationality, earnings, birthdate, team, earningsbyyear'
	end

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('earnings'), Comparator.gt, 0)}

	local data = {}

	local processData = function(item)
		table.insert(data, item)
	end

	local queryParameters = {
		conditions = conditions:toString(),
		limit = MAX_QUERY_LIMIT,
		query = queryFields,
	}

	Lpdb.executeMassQuery(opponentType, queryParameters, processData)

	local earningsFunction = function (a)
		if String.isNotEmpty(args.year) then
			return a.earningsbyyear[tonumber(args.year)] or 0
		else
			return tonumber(a.earnings) or 0
		end
	end

	table.sort(data, function(a, b) return earningsFunction(a) > earningsFunction(b) end)

	return Array.sub(data, 1, args.limit)
end

---@param config table
---@param chartData table
---@return Renderable
function StatisticsPortal._drawChart(config, chartData)
	return Html.Div{
		classes = {'table-responsive'},
		children = mw.ext.Charts.chart({
			grid = {
				left = '15%',
				right = '12%',
				top = '15%',
				bottom = '10%'
			},
			size = {
				height = config.height,
				width = config.width,
			},
			tooltip = {
				trigger = 'axis',
			},
			legend = config.customLegend,
			yAxis = config.flipAxes and config.xAxis or config.yAxis,
			xAxis = config.flipAxes and config.yAxis or config.xAxis,
			series = chartData,
			labels = config.labels,
		})
	}
end

---@param config table
---@param yearSeriesData table
---@param nonYearCategories table
---@param transpose boolean?
---@return Renderable
function StatisticsPortal._buildChartData(config, yearSeriesData, nonYearCategories, transpose)
	local yearTable, defaultYearTable = StatisticsPortal._returnCustomYears(config)
	local prevYear = config.startYear

	local yearList = {}
	local chartData = {}
	local seriesData = {}
	local earningsTable = Array.mapRange(1, Table.size(nonYearCategories), function() return 0 end)

	for yearIndex, yearValue in pairs(defaultYearTable) do
		earningsTable = StatisticsPortal._addArrays({earningsTable, yearSeriesData[yearIndex]})
		if Array.any(Array.extractValues(yearTable), function(value) return value == yearValue end) then
			local yearText = StatisticsPortal._returnCustomYearText(prevYear, yearValue)
			table.insert(yearList, yearText)
			table.insert(seriesData, earningsTable)
			prevYear = yearValue + 1
			earningsTable = Array.mapRange(1, Table.size(nonYearCategories), function() return 0 end)
		end
	end

	local categoryNames = nonYearCategories
	local seriesNames = yearList

	if transpose == true then
		seriesData = Array.mapRange(1, Table.size(nonYearCategories), function(index)
			return Array.map(seriesData, function(teamData)
				return teamData[index] or 0
			end)
		end)
		seriesNames, categoryNames = categoryNames, seriesNames
	end

	if config.removeEmptyCategories == true then
		categoryNames, seriesData = StatisticsPortal._removeCategories(categoryNames, seriesData)
	end

	for seriesIndex, series in pairs(seriesNames) do
		if config.removeEmptySeries == true and Array.all(seriesData[seriesIndex], function(value)
			return value == 0
		end) then
			mw.logObject(series .. ' is empty')
		else
			table.insert(chartData, {
					name = series,
					type = config.chartType,
					stack = config.stackType,
					data = seriesData[seriesIndex],
					emphasis = {focus = config.emphasis},
				}
			)
		end
	end

	config.yAxis = {
		type = 'value',
		name = 'Earnings ($USD)'
	}
	config.xAxis = {
		type = 'category',
		name = config.catLabel,
		data = categoryNames,
		axisTick = {
			alignWithLabel = true,
		},
		axisLabel = {
			rotate = config.axisRotate,
		},
	}
	if Table.isEmpty(config.customLegend) then
		config.customLegend = seriesNames
	end

	return StatisticsPortal._drawChart(config, chartData)
end

---@param categoryNames table
---@param seriesData table
---@return table, table
function StatisticsPortal._removeCategories(categoryNames, seriesData)
	local startsEmpty = true
	local lastNotEmpty = 1

	local isEmptyCategory = Array.map(Array.map(categoryNames, function(_, catIndex)
		local truthValue = Array.all(Array.map(seriesData, function(_, index)
			return seriesData[index][catIndex] end), function(value)
				return value == 0
			end)
			if not truthValue then
				lastNotEmpty = catIndex
			end
			return truthValue
		end),
	function(value, index)
		if index > lastNotEmpty then
			return false
		elseif startsEmpty and value == true then
			return false
		else
			startsEmpty = false
			return true
		end
	end)

	categoryNames = Array.filter(categoryNames, function(_, catIndex)
		return Logic.readBool(isEmptyCategory[catIndex]) end)

	seriesData = Array.map(seriesData, function(_, index)
		return Array.filter(seriesData[index], function(_, catIndex)
			return Logic.readBool(isEmptyCategory[catIndex])
		end)
	end)
	return categoryNames, seriesData
end

---@param args table
---@param params table
---@return table
function StatisticsPortal._getChartConfig(args, params)
	local isForTeam = String.isNotEmpty(args.team) or Logic.readBool(args.isForTeam)
	local customInputs = StatisticsPortal._isTableOrSplitOrDefault(args.customInputs, params.defaultInputs)
	local opponentName
	if isForTeam then
		opponentName = args.team
	else
		opponentName = args.player
	end

	return {
		processFunction = params.processFunction,
		variable = params.variable,
		catLabel = params.catLabel,
		flipAxes = params.flipAxes or false,
		axisRotate = params.axisRotate or 0,
		emphasis = params.emphasis or 'series',
		customInputs = customInputs,
		customLegend = StatisticsPortal._isTableOrSplitOrDefault(args.customLegend, customInputs),
		customYears = args.customYears,
		startYear = args.startYear or Info.startYear,
		yearBreakdown = Logic.readBool(args.yearBreakdown),
		removeEmptyCategories = Logic.readBool(args.removeEmptyCategories),
		removeEmptySeries = Logic.readBool(args.removeEmptySeries),
		chartType = args.chartType or 'bar',
		stackType = args.stackType or 'total',
		isForTeam = isForTeam,
		opponentName = opponentName,
		opponentType = isForTeam and Opponent.team or Opponent.solo,
		maxOpponents = tonumber(args.maxOpponents) or MAX_OPPONENT_LIMIT,
		height = tonumber(args.height) or 400,
		width = tonumber(args.width) or 1400,
	}
end

---@param input string|table|nil
---@param default table?
---@return table
function StatisticsPortal._isTableOrSplitOrDefault(input, default)
	if type(input) == 'table' then
		return input
	elseif String.isEmpty(input) then
		return default or {}
	end
	return Array.parseCommaSeparatedString(input)
end

---@param args table
---@return table, table
function StatisticsPortal._returnCustomYears(args)
	args.startYear = tonumber(args.startYear) or Info.startYear
	local yearTable
	local defaultYearTable = Array.range(args.startYear, CURRENT_YEAR)
	if String.isNotEmpty(args.customYears) then
		yearTable = Array.map(
			StatisticsPortal._isTableOrSplitOrDefault(args.customYears),
			function(tier)
				return tonumber(tier)
			end
		)
		table.insert(yearTable, CURRENT_YEAR)
		return yearTable, defaultYearTable
	else
		return defaultYearTable, defaultYearTable
	end
end

---@param prevYear number
---@param yearValue number
---@return string|number
function StatisticsPortal._returnCustomYearText(prevYear, yearValue)
	return (prevYear == yearValue) and yearValue or
		'\'' .. (string.sub(prevYear, 3, 4) .. '-' .. string.sub(yearValue, 3, 4))
end

---@param arrays table
---@return table
function StatisticsPortal._addArrays(arrays)
	return Array.map(arrays[1], function(_, index)
		return Array.reduce(Array.map(arrays, Operator.property(index)), Operator.add)
	end)
end

return Class.export(StatisticsPortal, {exports = {'topEarningsChart'}})
