---
-- @Liquipedia
-- page=Module:PortalStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

return {
	gameEarningsChart = Lua.lazyExport('Module:PortalStatistics/GameEarningsChart', 'gameEarningsChart'),
	modeEarningsChart = Lua.lazyExport('Module:PortalStatistics/ModeEarningsChart', 'modeEarningsChart'),
	topEarningsChart = Lua.lazyExport('Module:PortalStatistics/TopEarningsChart', 'topEarningsChart'),
	coverageStatistics = Lua.lazyExport('Module:PortalStatistics/CoverageStatistics', 'coverageStatistics'),
	coverageMatchTable = Lua.lazyExport('Module:PortalStatistics/CoverageMatchTable', 'coverageMatchTable'),
	coverageTournamentTable = Lua.lazyExport('Module:PortalStatistics/CoverageTournamentTable', 'coverageTournamentTable'),
	prizepoolBreakdown = Lua.lazyExport('Module:PortalStatistics/PrizepoolBreakdown', 'prizepoolBreakdown'),
	pieChartBreakdown = Lua.lazyExport('Module:PortalStatistics/PieChartBreakdown', 'pieChartBreakdown'),
	earningsTable = Lua.lazyExport('Module:PortalStatistics/EarningsTable', 'earningsTable'),
	playerAgeTable = Lua.lazyExport('Module:PortalStatistics/PlayerAgeTable', 'playerAgeTable'),
}
