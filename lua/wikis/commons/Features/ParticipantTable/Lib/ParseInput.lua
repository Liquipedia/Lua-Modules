---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Lib/ParseInput
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Info = Lua.import('Module:Info', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Namespace = Lua.import('Module:Namespace')
local Opponent = Lua.import('Module:Opponent/Custom')
local Set = Lua.import('Module:Set')
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


	local shouldStore
	if Logic.readBool(args.noStorage) then
		shouldStore = false
	elseif parentConfig.storage ~= nil then
		shouldStore = parentConfig.storage
	else
		shouldStore = Namespace.isMain() and not Lpdb.isStorageDisabled()
	end

	local config = {
		lpdbPrefix = args.lpdbPrefix or parentConfig.lpdbPrefix or Variables.varDefault('lpdbPrefix'),
		storage = shouldStore,
		matchGroupSpec = TournamentStructure.readMatchGroupsSpec(args),
		syncPlayers = Logic.nilOr(Logic.readBoolOrNil(args.syncPlayers), parentConfig.syncPlayers, true),
		showCountBySection = Logic.readBool(args.showCountBySection or parentConfig.showCountBySection),
		count = tonumber(args.count),
		colSpan = parentConfig.colSpan or MathUtil.toInteger(args.colspan) or 4,
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

---@param args table
---@param config ParticipantTableConfig
---@return ParticipantTableSection[]
function Parser.readSections(args, config)
	local sectionsArgs = Array.mapIndexes(function (index)
		local parsed = Json.parseIfTable(args[index])
		if type(parsed) == 'table' and parsed.type == 'section' then
			return parsed
		end
	end)
	--case no sections: use whole table as first section
	if Logic.isEmpty(sectionsArgs) then
		sectionsArgs = {args}
	end

	return Array.map(sectionsArgs, function(sectionArgs)
		local sectionConfig = Parser.readConfig(sectionArgs, config)
		return {
			config = sectionConfig,
			entries = Parser._readEntries(sectionArgs, sectionConfig)
		}
	end)
end

---@param args table
---@param config ParticipantTableConfig
---@return ParticipantTableEntry[]
function Parser._readEntries(args, config)
	---@type Set<string>
	local alreadyUsed = Set{}

	return Table.mapArgumentsByPrefix(args, {'p', 'player'}, function(key, index)
		local entry = Parser._readEntry(args, key, index, config)
		entry.sortName = Opponent.toName(entry.opponent)

		if entry.opponent and Opponent.isTbd(entry.opponent) then
			entry.name = Opponent.toName(entry.opponent)
			return entry
		end

		entry.opponent = Opponent.resolve(entry.opponent, config.resolveDate, {
			syncPlayer = config.syncPlayers,
			overwritePageVars = true,
		})
		entry.isResolved = true
		entry.name = Opponent.toName(entry.opponent)

		if alreadyUsed:contains(entry.name) then
			error('Duplicate Input "|' .. key .. '=' .. args[key] .. '"')
		end

		alreadyUsed:add(entry.name)

		return entry
	end)
end

---@param sectionArgs table
---@param key string
---@param index integer
---@param config ParticipantTableConfig
---@return ParticipantTableEntry
function Parser._readEntry(sectionArgs, key, index, config)
	local prefix = 'p' .. index
	local valueFromArgs = function(postfix)
		return sectionArgs[key .. postfix] or sectionArgs[prefix .. postfix]
	end

	--if not a json assume it is a solo opponent
	local opponentArgs = Json.parseIfTable(sectionArgs[key]) or {
		type = Opponent.solo,
		name = sectionArgs[key],
		link = valueFromArgs('link'),
		flag = valueFromArgs('flag'),
		team = valueFromArgs('team'),
		dq = valueFromArgs('dq'),
		note = valueFromArgs('note'),
		seed = valueFromArgs('seed'),
		faction = valueFromArgs('faction') or valueFromArgs('race'),
	}

	assert(Opponent.isType(opponentArgs.type), 'Invalid opponent type for "' .. sectionArgs[key] .. '"')

	opponentArgs.seed = tonumber(opponentArgs.seed)

	--unset wiki var for random events to not read players as random if prize pool already sets them as random
	if config.isRandomEvent and opponentArgs.type == Opponent.solo then
		Variables.varDefine(opponentArgs.name .. '_faction', '')
	end
	local opponent = Opponent.readOpponentArgs(opponentArgs)

	if config.sortPlayers and opponent.players then
		Array.sortInPlaceBy(opponent.players, function(player) return (player.displayName or player.pageName):lower() end)
	end

	return {
		dq = Logic.readBool(opponentArgs.dq),
		note = opponentArgs.note,
		opponent = opponent,
		seed = opponentArgs.seed,
	}
end

return Parser
