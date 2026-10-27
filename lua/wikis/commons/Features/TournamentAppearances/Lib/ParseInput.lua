---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Lib/Parse
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Types = Lua.import('Module:Features/TournamentAppearances/Types')

local Parser = {}

---@param args table
---@return TournamentAppearancesConfig
function Parser.readConfig(args)
	assert(
		args.series or args.pages or args.conditions,
		'Either "series", "pages" or "conditions" input has to be specified'
	)

	local config = {
		showPlacementInsteadOfTeam = Logic.readBool(args.showPlacementInsteadOfTeam),
		limit = tonumber(args.limit),
		isFormQuery = Logic.readBool(args.query),
		restrictToPlayersParticipatingIn = args.playerspage,
		restrictToFirstPrizePool = Logic.readBool(args.restrictToFirstPrizePool),
		player = Logic.nilOr(Logic.readBoolOrNil(args.player), true),
		staff = Logic.readBool(args.staff),
		conditions = args.conditions,
		tierTypes = Logic.emptyOr(Array.parseCommaSeparatedString(args.tierTypes), Types.DEFAULT_TIERTYPES),
		tiers = Array.parseCommaSeparatedString(args.tiers),
		startDate = Logic.nilIfEmpty(args.sdate),
		endDate = Logic.nilIfEmpty(args.edate),
		pages = Array.parseCommaSeparatedString(args.pages),
		series = args.series and Array.map(
			Array.extractValues(Table.filterByKey(args, function(key) return key:find('^series%d-$') end)),
			Page.pageifyLink
		) or nil,
	}

	-- todo: add option for opponent case
	assert(config.player or config.staff, 'Invalid config: at least one of |player= or |staff= must be true')

	return config
end

---@param config TournamentAppearancesConfig
---@return ConditionTree|string
function Parser.readTournamentConditionInputs(config)
	if config.conditions then
		return config.conditions
	end

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('enddate'), Comparator.gt, DateExt.defaultDate)}

	conditions:add(ConditionUtil.anyOf(ColumnName('status'), {'finished', ''}))
	conditions:add(ConditionUtil.anyOf(ColumnName('liquipediatier'), config.tiers))
	conditions:add(ConditionUtil.anyOf(ColumnName('liquipediatiertype'), config.tierTypes))

	if Table.isNotEmpty(config.series) then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionUtil.anyOf(ColumnName(1, 'serieslist'), config.series),
			ConditionUtil.anyOf(ColumnName(2, 'serieslist'), config.series),
		})
	else
		conditions:add(ConditionUtil.anyOf(ColumnName('pagename'), Array.map(config.pages, Page.pageifyLink)))
	end

	if config.startDate then
		conditions:add(ConditionNode(ColumnName('startdate'), Comparator.ge, config.startDate))
	end

	if config.endDate then
		conditions:add(ConditionNode(ColumnName('enddate'), Comparator.le, config.endDate))
	end

	return conditions
end

return Parser
