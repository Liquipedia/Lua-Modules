---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Api = Lua.import('Module:Features/SeriesMedalStatistics/Api/FetchPlacements')
local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Footer = Lua.import('Module:Features/SeriesMedalStatistics/Components/Footer')
local Logic = Lua.import('Module:Logic')
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
		mw.ext.TeamLiquidIntegration.add_category('Pages with empty SeriesMedalStatistic')
		return
	end

	---@type {opponents: table<string, standardOpponent>, teams: table<string, string>,
	---medalsData: table<string, SeriesMedalStatsDataSet>}
	local data = {
		opponents = {},
		teams = {},
		medalsData = {},
	}
	Array.forEach(placements, FnUtil.curry(FnUtil.curry(Processor.run, data), config))

	return MedalsTable{
		medalsTableType = config.medalsTableType,
		dataColumns = config.columns,
		data = data.medalsData,
		renderRowFirstCell = RowFirstCell.run(config.statsType, data.opponents),
		rowSort = Sort.rowSort,
		hideTotalRow = true,
		cutAfter = config.cutAfter,
		footer = Footer.run(config.statsType),
	}
end

return SeriesMedalStatistics
