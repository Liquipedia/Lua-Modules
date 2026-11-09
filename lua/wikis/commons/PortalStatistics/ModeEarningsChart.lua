---
-- @Liquipedia
-- page=Module:PortalStatistics/ModeEarningsChart
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local ChartHelper = Lua.import('Module:PortalStatistics/ChartHelper')

local MODES = {'solo', 'team', 'other'}

local ModeEarningsChart = {}

---@param args table?
---@return Renderable
function ModeEarningsChart.modeEarningsChart(args)
	args = args or {}

	local params = {
		variable = 'opponenttype',
		processFunction = ChartHelper.defaultProcessFunction,
		catLabel = 'Year',
		defaultInputs = MODES,
		axisRotate = tonumber(args.axisRotate),
	}

	local config = ChartHelper.getChartConfig(args, params)
	local yearSeriesData = ChartHelper.getPlacementEarningsByYear(config)
	return ChartHelper.buildChartData(config, yearSeriesData, config.customLegend, true)
end

return Class.export(ModeEarningsChart, {exports = {'modeEarningsChart'}})
