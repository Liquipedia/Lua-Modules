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
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')

local ChartHelper = Lua.import('Module:PortalStatistics/ChartHelper')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CURRENT_YEAR = DateExt.getYearOf()
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

	local config = ChartHelper.getChartConfig(args, params)
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
		return ChartHelper.buildChartData(config, yearSeriesData, opponentNames)
	else
		local chartData = {}
		chartData[1] = {
			name = 'Total Earnings',
			type = 'bar',
			stack = config.stackType,
			data = ChartHelper.addArrays(yearSeriesData),
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
		return ChartHelper.drawChart(config, chartData)
	end
end


--[[
Section: Query Functions
]]--

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

	local earningsFunction = function (a)
		if String.isNotEmpty(args.year) then
			return a.earningsbyyear[tonumber(args.year)] or 0
		else
			return tonumber(a.earnings) or 0
		end
	end

	if String.isEmpty(args.year) then
		-- Total earnings are a plain column, so let LPDB do the ordering and only fetch the rows that are displayed.
		queryParameters.order = 'earnings desc'
		queryParameters.limit = math.min(args.limit, MAX_QUERY_LIMIT)
		Lpdb.executeMassQuery(opponentType, queryParameters, processData, args.limit)
	else
		-- Earnings by year are stored in a json field, which can not be sorted by LPDB.
		Lpdb.executeMassQuery(opponentType, queryParameters, processData)
	end

	table.sort(data, function(a, b) return earningsFunction(a) > earningsFunction(b) end)

	return Array.sub(data, 1, args.limit)
end

return Class.export(StatisticsPortal, {exports = {'topEarningsChart'}})
