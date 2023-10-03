---
-- @Liquipedia
-- wiki=commons
-- page=Module:ParticipantTable/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

---@class StarcraftParticipantTableConfig: ParticipantTableConfig
---@field displayUnknownColumn boolean?
---@field displayRandomColumn boolean?
---@field showCountByRace boolean
---@field isRandomEvent boolean
---@field isQualified boolean?
---@field manualFactionCounts {p: number?, t: number?, z: number?, r: number?}

---@class StarcraftParticipantTableEntry: ParticipantTableEntry
---@field isQualified boolean?
---@field opponent StarcraftStandardOpponent

---@class StarcraftParticipantTableSection: ParticipantTableSection
---@field entries StarcraftParticipantTableEntry[]

---@class StarcraftParticipantTable: ParticipantTable
---@field isPureSolo boolean
local ParticipantTable = Lua.import('Module:ParticipantTable/Starcraft', {requireDevIfEnabled = true})

local OpponentLibraries = require('OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local prizePoolVars = PageVariableNamespace('PrizePool')

local ROLL_OUT_DATE = '2023-10-31'

local StarcraftParticipantTable = {}

---@param frame Frame
---@return Html?
function StarcraftParticipantTable.run(frame)
	local participantTable = ParticipantTable(frame)

	participantTable.args.noStorage = participantTable.args.noStorage or
		Variables.varDefault('tournament_startdate') > ROLL_OUT_DATE

	participantTable.readConfig = StarcraftParticipantTable.readConfig
	participantTable.readEntry = StarcraftParticipantTable.readEntry
	participantTable.buildExtradata = StarcraftParticipantTable.buildExtradata
	participantTable.getPlacements = StarcraftParticipantTable.getPlacements
	participantTable.displaySoloRaceTableSection = StarcraftParticipantTable.displaySoloRaceTableSection



	participantTable:init():store()

	if StarcraftParticipantTable.isPureSolo(participantTable.sections) then
		participantTable.create = StarcraftParticipantTable.createSoloRaceTable
	end

	return participantTable:create()
end

---@param args table
---@param parentConfig StarcraftParticipantTableConfig?
---@return StarcraftParticipantTableConfig
function StarcraftParticipantTable.readConfig(args, parentConfig)
	local config = ParticipantTable.readConfig(args, parentConfig)
	parentConfig = parentConfig or {}

	config.displayUnknownColumn = Logic.readBoolOrNil(args.unknowncolumn)
	config.displayRandomColumn = Logic.readBoolOrNil(args.unknowncolumn)
	config.showCountByRace = Logic.readBool(args.showCountByRace or args.count)
	config.isRandomEvent = Logic.readBool(args.is_random_event)
	config.isQualified = Logic.nilOr(Logic.readBoolOrNil(args.isQualified), parentConfig.isQualified)
	config.sortOpponents = Logic.nilOr(Logic.readBoolOrNil(args.sortOpponents or parentConfig.sortOpponents), true)
	config.sortPlayers = true
	config.manualFactionCounts = {
		p = tonumber(args.protoss),
		t = tonumber(args.terran),
		z = tonumber(args.zerg),
		r = tonumber(args.random),
	}
	config.columnWidth = tonumber(args.columnWidth)

	return config
end

---@param sectionArgs table
---@param key string|number
---@param config any
---@return StarcraftParticipantTableEntry
function StarcraftParticipantTable:readEntry(sectionArgs, key, config)
	--if not a json assume it is a solo opponent
	local opponentArgs = Json.parseIfTable(sectionArgs[key]) or Logic.isNumeric(key) and {
		type = Opponent.solo,
		name = sectionArgs[key],
	} or {
		type = Opponent.solo,
		name = sectionArgs[key],
		link = sectionArgs[key .. 'link'],
		flag = sectionArgs[key .. 'flag'],
		team = sectionArgs[key .. 'team'],
		race = sectionArgs[key .. 'race'],
	}

	assert(Opponent.isType(opponentArgs.type) and opponentArgs.type ~= Opponent.team,
		'Missing or unsupported opponent type for "' .. sectionArgs[key] .. '"')

	local opponent = Opponent.readOpponentArgs(opponentArgs)

	if config.sortPlayers and opponent.players then
		table.sort(opponent.players, function (player1, player2)
			local name1 = (player1.displayName or player1.name):lower()
			local name2 = (player2.displayName or player2.name):lower()
			return name1 < name2
		end)
	end

	return {
		dq = Logic.readBool(opponentArgs.dq or sectionArgs[key .. 'dq']),
		note = opponentArgs.note or sectionArgs[key .. 'note'],
		opponent = opponent,
		name = Opponent.toName(opponent),
		isQualified = Logic.nilOr(Logic.readBoolOrNil(sectionArgs[key .. 'qualified']) or config.isQualified),
	}
end

---@param lpdbData table
---@param entry table
---@return table
function StarcraftParticipantTable:buildExtradata(lpdbData, entry)
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return {
		seriesnumber = seriesNumber and string.format('%05d', seriesNumber) or nil,
		isqualified = tostring(entry.isQualified),
	}

end

---@return table<string, true>
function StarcraftParticipantTable:getPlacements()
	local placements = {}
	local maxPrizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0

	for prizePoolIndex = 1, maxPrizePoolIndex do
		Array.forEach(Json.parseIfTable(prizePoolVars:get('placementRecords.' .. prizePoolIndex)) or {}, function(placement)
			placements[placement.opponentname] = true
		end)
	end

	return placements
end

function StarcraftParticipantTable.isPureSolo(sections)
	return Array.all(sections, function(section) return Array.all(section.entries, function(entry)
		return entry.opponent.type == Opponent.solo
	end) end)
end

---@return Html?
function StarcraftParticipantTable:createSoloRaceTable()
	if not self.config.display then return end

	local factioNumbers = StarcraftParticipantTable:_getFactionNumbers()

	local config = self.config

	local factionColumns
	if not config.isRandomEvent and
		(config.displayRandomColumn or config.displayRandomColumn == nil and factioNumbers.r > 0) then

		factionColumns = Faction.knownFactions
	else
		factionColumns = Faction.coreFactions
	end

	if config.displayUnknownColumn or config.displayUnknownColumn == nil and factioNumbers[Faction.defaultFaction] > 0 then
		Array.appendWith(factionColumns, Faction.defaultFaction)
	end

	self.display = mw.html.create('div')
		:addClass('participant-table')
		:css('grid-template-columns', 'repeat(' .. #factionColumns .. ', 1fr)')
		:css('width', config.columnWidth and (#factionColumns * config.columnWidth .. 'px') or nil)
		:node(StarcraftParticipantTable:_displayHeader(factionColumns, factioNumbers))

	Array.forEach(self.sections, function(section) self:displaySoloRaceTableSection(section, factionColumns) end)

	return self.display
end

---@return table
function StarcraftParticipantTable:_getFactionNumbers()
	local calculatedNumbers = Table.map(Faction.factions, function(key, faction) return faction, 0 end)
	Array.forEach(self.sections, function(section)
		section.entries = section.config.onlyNotable and self.filterOnlyNotables(section.entries) or section.entries

		Array.forEach(section.entries, function(entry)
			local faction = entry.opponent.players[1].race
			calculatedNumbers[faction] = calculatedNumbers[faction] + 1
		end)
	end)

	for faction, value in pairs(calculatedNumbers) do
		calculatedNumbers[faction] = self.config.manualFactionCounts[faction] or value
	end

	return calculatedNumbers
end

---@param factionColumns table
---@param factioNumbers table
---@return Html
function StarcraftParticipantTable:_displayHeader(factionColumns, factioNumbers)
	local config = self.config
	local header = mw.html.create('div'):addClass('participant-table-header')

	Array.forEach(factionColumns, function(faction)
		local parts = Array.extend(
			config.isRandomEvent and Faction.Icon{faction = 'r'} or nil,
			faction ~= Faction.defaultFaction and Faction.Icon{faction = faction} or nil,
			' ' .. Faction.toName(faction),
			config.isRandomEvent and ' Main' or nil,
			config.showCountByRace and " ''(" .. factioNumbers[faction] .. ")''" or nil
		)

		header:tag('div')
			:addClass('participant-table-race-header opponent-list-cell')
			:addClass(Faction.bgClass(faction))
			:tag('div')
				:addClass('opponent-list-cell-content')
				:wikitext(table.concat(parts))
	end)

	return header
end

---@param section StarcraftParticipantTableSection
---@param factionColumns table
function StarcraftParticipantTable:displaySoloRaceTableSection(section, factionColumns)
	local sectionNode = mw.html.create('div')
		:addClass('participant-table-section')
		:node(self.sectionTitle(section, #section.entries))

	if Table.isEmpty(section.entries) then
		self.display:node(sectionNode:node(self.tbd()))
		return
	end

	-- Group entries by faction
	local _, byFaction = Array.groupBy(section.entries, function(entry) return entry.opponent.players[1].race end)

	-- Find the race with the most players
	local maxRaceLength = Array.max(
		Array.map(factionColumns, function(faction) return #(byFaction[faction] or {}) end)
	) or 0

	Array.forEach(Array.range(1, maxRaceLength), function(rowIndex)
		Array.forEach(factionColumns, function(faction)
			local entry = byFaction[faction] and byFaction[faction][rowIndex]
			sectionNode:node(
				entry and self:displayEntry(entry) or
				mw.html.create('div'):addClass('opponent-list-cell')
			)
		end)
	end)

	self.display:node(sectionNode)
end

return StarcraftParticipantTable
