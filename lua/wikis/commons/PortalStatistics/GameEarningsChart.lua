---
-- @Liquipedia
-- page=Module:PortalStatistics/GameEarningsChart
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')

local ChartHelper = Lua.import('Module:PortalStatistics/ChartHelper')
local Util = Lua.import('Module:PortalStatistics/Util')

local GameEarningsChart = {}

---@param args table?
---@return Renderable
function GameEarningsChart.gameEarningsChart(args)
	args = args or {}

	local games = Array.map(Util.isTableOrSplitOrDefault(args.customGames, Util.GAMES), function(game)
		return Game.toIdentifier{game = game, useDefault = false} or game
	end)

	local params = {
		variable = 'game',
		processFunction = ChartHelper.defaultProcessFunction,
		catLabel = 'Year',
		defaultInputs = games,
		axisRotate = tonumber(args.axisRotate),
	}

	local config = ChartHelper.getChartConfig(args, params)
	local yearSeriesData = ChartHelper.getPlacementEarningsByYear(config)
	return ChartHelper.buildChartData(config, yearSeriesData, config.customLegend, true)
end

return Class.export(GameEarningsChart, {exports = {'gameEarningsChart'}})
