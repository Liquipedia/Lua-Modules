---
-- @Liquipedia
-- page=Module:PortalStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local GameEarningsChart = Lua.import('Module:PortalStatistics/GameEarningsChart')
local ModeEarningsChart = Lua.import('Module:PortalStatistics/ModeEarningsChart')
local TopEarningsChart = Lua.import('Module:PortalStatistics/TopEarningsChart')
local CoverageStatistics = Lua.import('Module:PortalStatistics/CoverageStatistics')
local CoverageMatchTable = Lua.import('Module:PortalStatistics/CoverageMatchTable')
local CoverageTournamentTable = Lua.import('Module:PortalStatistics/CoverageTournamentTable')
local PrizepoolBreakdown = Lua.import('Module:PortalStatistics/PrizepoolBreakdown')
local PieChartBreakdown = Lua.import('Module:PortalStatistics/PieChartBreakdown')
local EarningsTable = Lua.import('Module:PortalStatistics/EarningsTable')
local PlayerAgeTable = Lua.import('Module:PortalStatistics/PlayerAgeTable')

return {
	gameEarningsChart = GameEarningsChart.gameEarningsChart,
	modeEarningsChart = ModeEarningsChart.modeEarningsChart,
	topEarningsChart = TopEarningsChart.topEarningsChart,
	coverageStatistics = CoverageStatistics.coverageStatistics,
	coverageMatchTable = CoverageMatchTable.coverageMatchTable,
	coverageTournamentTable = CoverageTournamentTable.coverageTournamentTable,
	prizepoolBreakdown = PrizepoolBreakdown.prizepoolBreakdown,
	pieChartBreakdown = PieChartBreakdown.pieChartBreakdown,
	earningsTable = EarningsTable.earningsTable,
	playerAgeTable = PlayerAgeTable.playerAgeTable,
}
