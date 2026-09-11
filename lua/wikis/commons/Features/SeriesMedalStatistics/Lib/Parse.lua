---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Lib/Parse
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Types = Lua.import('Module:Features/SeriesMedalStatistics/Types')

local Parser = {}

---@param args table
---@return SeriesMedalStatsConfig
function Parser.readConfig(args)
	local statsType = assert(Types.statsTypes[args.statsType], 'Invalid or unset statsType')
	local columns = Array.extend(
		1,
		2,
		Logic.readBool(args.bronze) and Types.optionalPlacementColumns.THIRD or nil,
		Logic.readBool(args.sf) and Types.optionalPlacementColumns.SEMIFINALIST or nil,
		Logic.readBool(args.copper) and Types.optionalPlacementColumns.FOURTH or nil,
		'total'
	)

	local config = {
		statsType = statsType,
		cutAfter = MathUtil.toInteger(args.cutafter) or 7,
		columns = columns,
		mergeIntoSemifinalists = Logic.readBool(args.mergeIntoSemifinalists),
		offset = MathUtil.toInteger(args.offset),
		limit = MathUtil.toInteger(args.limit),
		medalsTableType = Types.medalsTableTypes[statsType],
	}
	config.query = Parser._readQueryConfig(args, config)


	return config
end

---@param args table
---@param config table
---@return SeriesMedalStatsConditionConfig
function Parser._readQueryConfig(args, config)
	local series = Array.parseCommaSeparatedString(args.series or mw.title.getCurrentTitle().prefixedText)
	if not Logic.readBool(args.noredirect) then
		series = Array.map(series, mw.ext.TeamLiquidIntegration.resolve_redirect)
	end
	series = Array.map(series, function(value) return (value:gsub('_', ' ')) end)

	return {
		series = series,
		tier = Array.parseCommaSeparatedString(args.tier),
		tierType = Array.parseCommaSeparatedString(args.tiertype),
		startDate = DateExt.readTimestamp(args.sdate),
		endDate = DateExt.readTimestamp(args.edate),
		additionalConditions = args.additionalConditions or '',
		opponentTypes = Array.parseCommaSeparatedString(args.opponentType),
		columns = config.columns,
	}
end

return Parser
