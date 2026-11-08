---
-- @Liquipedia
-- page=Module:PortalStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

return {
	gameEarningsChart = Lua.lazyExport('GameEarningsChart', 'gameEarningsChart'),
	modeEarningsChart = Lua.lazyExport('ModeEarningsChart', 'modeEarningsChart'),
	topEarningsChart = Lua.lazyExport('TopEarningsChart', 'topEarningsChart'),
	coverageStatistics = Lua.lazyExport('CoverageStatistics', 'coverageStatistics'),
	coverageMatchTable = Lua.lazyExport('CoverageMatchTable', 'coverageMatchTable'),
	coverageTournamentTable = Lua.lazyExport('CoverageTournamentTable', 'coverageTournamentTable'),
	prizepoolBreakdown = Lua.lazyExport('PrizepoolBreakdown', 'prizepoolBreakdown'),
	pieChartBreakdown = Lua.lazyExport('PieChartBreakdown', 'pieChartBreakdown'),
	earningsTable = Lua.lazyExport('EarningsTable', 'earningsTable'),
	playerAgeTable = Lua.lazyExport('PlayerAgeTable', 'playerAgeTable'),
}
