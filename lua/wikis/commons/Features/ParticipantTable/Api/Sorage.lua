---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Api/Storage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')
local Variables = Lua.import('Module:Variables')

local prizePoolVars = PageVariableNamespace('PrizePool')

local Storage = {}

---@param sections ParticipantTableSection[]
---@param config ParticipantTableConfig
---@param adjustLpdbData? fun(lpdbData: table, entry: ParticipantTableEntry, config: ParticipantTableConfig)
function Storage.run(sections, config, adjustLpdbData)
	local tournamentContext = Tournament.partialTournamentFromContext()

	local lpdbTournamentData = {
		tournament = tournamentContext.fullName,
		parent = tournamentContext.pageName,
		series = tournamentContext.series,
		startdate = Variables.varDefault('tournament_startdate'),
		mode = tournamentContext.mode,
		type = tournamentContext.type,
		liquipediatier = tournamentContext.liquipediaTier,
		liquipediatiertype = tournamentContext.liquipediaTierType,
		publishertier = tournamentContext.publisherTier,
		icon = tournamentContext.icon,
		icondark = tournamentContext.iconDark,
		game = tournamentContext.game,
		prizepoolindex = tonumber(Variables.varDefault('prizepool_index')) or 0,
	}

	local placements = Storage._getPlacements()

	---@param section ParticipantTableSection
	---@param opponent standardOpponent
	---@return boolean
	local shouldNotStoreOpponent = function(section, opponent)
		return section.config.noStorage or
			opponent.type == Opponent.team or
			Opponent.isTbd(opponent) or
			Opponent.isEmpty(opponent)
	end

	Array.forEach(sections, function(section)
		Array.forEach(section.entries, function(entry)
			if shouldNotStoreOpponent(section, entry.opponent) then return end

			local lpdbData = Opponent.toLpdbStruct(entry.opponent)
			local placement = placements[lpdbData.opponentname]

			if placement then
				lpdbData = Table.deepMerge(
					lpdbData,
					placement
				)
			else
				lpdbData = Table.merge(
					lpdbTournamentData,
					lpdbData,
					{date = section.config.resolveDate, extradata = {dq = entry.dq and 'true' or nil}}
				)
			end

			if config.isRandomEvent then
				lpdbData.opponentplayers.p1faction = Faction.read('r')
			end

			if adjustLpdbData then
				adjustLpdbData(lpdbData, entry, section.config)
			end

			mw.ext.LiquipediaDB.lpdb_placement(Storage._objectName(lpdbData, config), Json.stringifySubTables(lpdbData))
		end)
	end)
end

---Get placements already set on the page from prize pools ABOVE the participant table
---@return table<string, placement>
function Storage._getPlacements()
	local placements = {}
	local maxPrizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0

	for prizePoolIndex = 1, maxPrizePoolIndex do
		Array.forEach(Json.parseIfTable(prizePoolVars:get('placementRecords.' .. prizePoolIndex)) or {}, function(placement)
			placements[placement.opponentname] = placement
		end)
	end

	return placements
end

---@param lpdbData table
---@param config ParticipantTableConfig
---@return string
function Storage._objectName(lpdbData, config)
	--this objectName comes from lpdbData passed along as wiki vars, e.g. sc, sc2, sg
	if Logic.isNotEmpty(lpdbData.objectName) then return lpdbData.objectName end

	--this objectName comes from queried lpdb data and has a prefixed pageid
	if Logic.isNotEmpty(lpdbData.objectname) then
		--remove then prefixed pageid from the objectName
		local objectName = lpdbData.objectname:gsub('^%d*_', '')
		return objectName
	end

	local lpdbPrefix = config.lpdbPrefix and ('_' .. config.lpdbPrefix) or ''
	return 'ranking' .. lpdbPrefix .. lpdbData.prizepoolindex .. '_' .. lpdbData.opponentname
end

return Storage
