---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Lib/ParseInput
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')
local Variables = Lua.import('Module:Variables')

local Parser = {}

---@param args table
---@param parentConfig ParticipantTableConfig?
---@return ParticipantTableConfig
function Parser.readConfig(args, parentConfig)
	parentConfig = parentConfig or {}

	local showTeams = not Logic.readBool(args.disable_teams)

	local config = {
		lpdbPrefix = args.lpdbPrefix or parentConfig.lpdbPrefix or Variables.varDefault('lpdbPrefix'),
		noStorage = Logic.readBool(args.noStorage or parentConfig.noStorage or
			Lpdb.isStorageDisabled() or not Namespace.isMain()),
		matchGroupSpec = TournamentStructure.readMatchGroupsSpec(args),
		syncPlayers = Logic.nilOr(Logic.readBoolOrNil(args.syncPlayers), parentConfig.syncPlayers, true),
		showCountBySection = Logic.readBool(args.showCountBySection or parentConfig.showCountBySection),
		count = tonumber(args.count),
		colSpan = parentConfig.colSpan or tonumber(args.colspan) or 4,
		onlyNotable = Logic.readBool(args.onlyNotable or parentConfig.onlyNotable),
		resolveDate = args.date or parentConfig.resolveDate or DateExt.getContextualDate(),
		sortPlayers = Logic.nilOr(Logic.readBoolOrNil(args.sortPlayers), Logic.readBoolOrNil(args.sortPlayers),
			(Info.config.participants or {}).sortPlayersInTable),
		sortOpponents = Logic.nilOr(Logic.readBoolOrNil(args.sortOpponents), parentConfig.sortOpponents, true),
		showTeams = showTeams,
		title = args.title,
		importOnlyQualified = Logic.readBool(args.onlyQualified),
		display = not Logic.readBool(args.hidden),
		showTitle = not Logic.readBool(args.hideTitle),
		-- the following configs only apply to faction table version
		soloAsFactionTable = Logic.nilOr(Logic.readBoolOrNil(args.soloAsFactionTable),
			(Info.config.participants or {}).soloAsFactionTable),
		displayUnknownColumn = Logic.readBoolOrNil(args.unknowncolumn),
		displayRandomColumn = Logic.readBoolOrNil(args.randomcolumn),
		displayMultipleFactionColumn = Logic.readBoolOrNil(args.multiplecolumn),
		isRandomEvent = Logic.nilOr(Logic.readBoolOrNil(args.is_random_event), parentConfig.isRandomEvent),
		manualFactionCounts = Table.map(Faction.knownFactions, function(key, faction)
			return faction, tonumber(args[Faction.toName(faction):lower()])
		end),
		factionColumnWidth = tonumber(args.entrywidth) or showTeams and 212 or 156,
	}

	config.width = parentConfig.width
	if not config.width then
		local columnWidth = parentConfig.columnWidth or tonumber(args.entrywidth) or showTeams and 212 or 156
		config.width = (columnWidth * config.colSpan) .. 'px'
	end
	config.columnWidth = config.columnWidth or ((100 / config.colSpan) .. '%')

	return config
end

return Parser
