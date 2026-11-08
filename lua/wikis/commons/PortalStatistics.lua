---
-- @Liquipedia
-- page=Module:PortalStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

---Every `#invoke` only needs a single statistic, so the submodules are imported on demand.
---Importing all of them up front loads (and executes the top level of) every widget, condition and display module
---for each call, which is a big part of the memory and lua time spent on pages using this module.
---@param moduleName string
---@param functionName string
---@return fun(...): any
local function lazyExport(moduleName, functionName)
	return function(...)
		return Lua.import('Module:PortalStatistics/' .. moduleName)[functionName](...)
	end
end

return {
	gameEarningsChart = lazyExport('GameEarningsChart', 'gameEarningsChart'),
	modeEarningsChart = lazyExport('ModeEarningsChart', 'modeEarningsChart'),
	topEarningsChart = lazyExport('TopEarningsChart', 'topEarningsChart'),
	coverageStatistics = lazyExport('CoverageStatistics', 'coverageStatistics'),
	coverageMatchTable = lazyExport('CoverageMatchTable', 'coverageMatchTable'),
	coverageTournamentTable = lazyExport('CoverageTournamentTable', 'coverageTournamentTable'),
	prizepoolBreakdown = lazyExport('PrizepoolBreakdown', 'prizepoolBreakdown'),
	pieChartBreakdown = lazyExport('PieChartBreakdown', 'pieChartBreakdown'),
	earningsTable = lazyExport('EarningsTable', 'earningsTable'),
	playerAgeTable = lazyExport('PlayerAgeTable', 'playerAgeTable'),
}
