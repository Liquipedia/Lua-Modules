---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local Api = Lua.import('Module:Features/SeriesMedalStatistics/Api/FetchPlacements')
local Footer = Lua.import('Module:Features/SeriesMedalStatistics/Components/Footer')
local GetTeamIdentifier = Lua.import('Module:Features/SeriesMedalStatistics/GetTeamIdentifier')
local Parser = Lua.import('Module:Features/SeriesMedalStatistics/Lib/Parse')
local Processor = Lua.import('Module:Features/SeriesMedalStatistics/Lib/Process')
local RowFirstCell = Lua.import('Module:Features/SeriesMedalStatistics/Components/RowFirstCell')
local Sort = Lua.import('Module:Features/SeriesMedalStatistics/Lib/Sort')

local MedalsTable = Lua.import('Module:Widget/MedalsTable')

local SeriesMedalStatistics = {}

-- wikicode entry point
---@param frame Frame
---@return VNode?
function SeriesMedalStatistics.run(frame)
	local args = Arguments.getArgs(frame)
	return SeriesMedalStatistics.execute(args)
end

---@param args table
---@return VNode?
function SeriesMedalStatistics.execute(args)
	local config = Parser.readConfig(args)

	local placements = Api.run(config.query)

	if Logic.isEmpty(placements) then
		-- tracking category to find cases where the return is empty so we can check why they are empty
		mw.ext.TeamLiquidIntegration.add_category('Pages with empty SeriesMedalStatistic')
		return
	end

	---@type SeriesMedalStatsData
	local data = {
		opponents = {},
		medalsData = {},
	}
	local teams = {}
	local getTeamIdentifier = FnUtil.curry(GetTeamIdentifier.run, teams)
	local process = FnUtil.curry(FnUtil.curry(FnUtil.curry(Processor.run, getTeamIdentifier), config), data)
	Array.forEach(placements, process)

	---@param identifier string
	---@return VNode
	local renderRowFirstCell = function(identifier)
		return RowFirstCell{statsType = config.statsType, opponents = data.opponents, identifier = identifier}
	end

	return MedalsTable{
		medalsTableType = config.medalsTableType,
		dataColumns = config.columns,
		data = data.medalsData,
		renderRowFirstCell = renderRowFirstCell,
		rowSort = Sort.rowSort,
		hideTotalRow = true,
		cutAfter = config.cutAfter,
		footer = Footer{statsType = config.statsType},
	}
end

return SeriesMedalStatistics
