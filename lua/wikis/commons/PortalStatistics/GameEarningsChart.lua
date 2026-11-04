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
local Info = Lua.import('Module:Info', {loadData = true})
local Table = Lua.import('Module:Table')

local ChartHelper = Lua.import('Module:PortalStatistics/ChartHelper')

local GAMES = Array.map(Array.extractValues(Info.games, Table.iter.spairs), function(value)
	return value.name
end)

local StatisticsPortal = {}

---@param args table?
---@return Renderable
function StatisticsPortal.gameEarningsChart(args)
	args = args or {}

	local games = Array.map(ChartHelper.isTableOrSplitOrDefault(args.customGames, GAMES), function(game)
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

return Class.export(StatisticsPortal, {exports = {'gameEarningsChart'}})
