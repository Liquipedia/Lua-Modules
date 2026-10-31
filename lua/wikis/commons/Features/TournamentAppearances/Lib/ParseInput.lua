---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Lib/ParseInput
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Types = Lua.import('Module:Features/TournamentAppearances/Types')

local ParseInput = {}

---@param args table
---@return TournamentAppearancesConfig
function ParseInput.readConfig(args)
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

return ParseInput
