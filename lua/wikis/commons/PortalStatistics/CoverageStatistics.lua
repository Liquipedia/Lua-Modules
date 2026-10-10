---
-- @Liquipedia
-- page=Module:PortalStatistics/CoverageStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local CoverageMatchTable = Lua.import('Module:PortalStatistics/CoverageMatchTable')
local CoverageTournamentTable = Lua.import('Module:PortalStatistics/CoverageTournamentTable')

local Box = Lua.import('Module:Widget/Basic/Box')
local Html = Lua.import('Module:Widget/Html')

local StatisticsPortal = {}

StatisticsPortal.coverageMatchTable = CoverageMatchTable.coverageMatchTable
StatisticsPortal.coverageTournamentTable = CoverageTournamentTable.coverageTournamentTable

---@param args table?
---@return VNode
function StatisticsPortal.coverageStatistics(args)
	args = args or {}
	args.alignSide = Logic.readBool(args.alignSide)

	local statsChildren = {
		StatisticsPortal.coverageTournamentTable(args),
		StatisticsPortal.coverageMatchTable(args)
	}

	if args.alignSide then
		return Box{
			paddingRight = '2em',
			children = statsChildren,
		}
	else
		return Html.Div{
			children = statsChildren,
		}
	end
end

return Class.export(StatisticsPortal, {exports = {'coverageStatistics'}})
