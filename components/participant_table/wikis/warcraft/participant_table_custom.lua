---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

---@class WarcraftParticipantTableConfig: ParticipantTableConfig
---@field displayUnknownColumn boolean?
---@field displayRandomColumn boolean?
---@field displayMultipleFactionColumn boolean?
---@field showCountByFaction boolean
---@field manualFactionCounts table<string, number?>
---@field soloColumnWidth number

---@class WarcraftParticipantTableEntry: ParticipantTableEntry
---@field opponent WarcraftStandardOpponent

---@class WarcraftParticipantTableSection: ParticipantTableSection
---@field entries WarcraftParticipantTableEntry[]

---@class WarcraftParticipantTable: ParticipantTable
---@field isPureSolo boolean
---@field _displaySoloFactionTableSection function
---@field _displayHeader function
---@field _getFactionNumbers function

local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local CustomParticipantTable = {}

---@param frame Frame
---@return Html?
function CustomParticipantTable.run(frame)
	local participantTable = ParticipantTable(frame) --[[@as WarcraftParticipantTable]]

	participantTable.readConfig = CustomParticipantTable.readConfig
	participantTable.readEntry = CustomParticipantTable.readEntry
	participantTable.adjustLpdbData = CustomParticipantTable.adjustLpdbData
	participantTable._displaySoloFactionTableSection = CustomParticipantTable._displaySoloFactionTableSection
	participantTable._displayHeader = CustomParticipantTable._displayHeader
	participantTable._getFactionNumbers = CustomParticipantTable._getFactionNumbers

	participantTable:read():store()

	if CustomParticipantTable.isPureSolo(participantTable.sections) then
		participantTable.create = CustomParticipantTable.createSoloFactionTable
	end

	return participantTable:create()
end

---@param args table
---@param parentConfig WarcraftParticipantTableConfig?
---@return WarcraftParticipantTableConfig
function CustomParticipantTable.readConfig(args, parentConfig)
	local config = ParticipantTable.readConfig(args, parentConfig) --[[@as WarcraftParticipantTableConfig]]

	config.displayUnknownColumn = Logic.readBoolOrNil(args.unknowncolumn)
	config.displayRandomColumn = Logic.readBoolOrNil(args.randomcolumn)
	config.displayMultipleFactionColumn = Logic.readBoolOrNil(args.multiplecolumn)
	config.showCountByFaction = Logic.readBool(args.showCountByRace or args.count)
	config.sortPlayers = true
	--only relevant for solo case since there we need columnWidth in px since colSpan is calculated dynamically
	config.soloColumnWidth = tonumber(args.entrywidth) or config.showTeams and 212 or 156

	config.manualFactionCounts = {}
	Array.forEach(Faction.knownFactions, function(faction)
		config.manualFactionCounts[faction] = tonumber(args[Faction.toName(faction):lower()])
	end)

	return config
end

---@param sectionArgs table
---@param key string|number
---@param index number
---@param config WarcraftParticipantTableConfig
---@return WarcraftParticipantTableEntry
function CustomParticipantTable:readEntry(sectionArgs, key, index, config)
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
		faction = valueFromArgs('race'),
	}

	assert(Opponent.isType(opponentArgs.type) and opponentArgs.type ~= Opponent.team,
		'Missing or unsupported opponent type for "' .. sectionArgs[key] .. '"')

	local opponent = Opponent.readOpponentArgs(opponentArgs) or {}

	if config.sortPlayers and opponent.players then
		table.sort(opponent.players, function (player1, player2)
			local name1 = (player1.displayName or player1.pageName):lower()
			local name2 = (player2.displayName or player2.pageName):lower()
			return name1 < name2
		end)
	end

	return {
		dq = Logic.readBool(opponentArgs.dq),
		note = opponentArgs.note,
		opponent = opponent,
		name = Opponent.toName(opponent),
	}
end

---@param lpdbData table
---@param entry WarcraftParticipantTableEntry
---@param config WarcraftParticipantTableConfig
function CustomParticipantTable:adjustLpdbData(lpdbData, entry, config)
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))

	lpdbData.extradata.seriesnumber = seriesNumber and string.format('%05d', seriesNumber) or nil
end

---@param sections WarcraftParticipantTableSection[]
---@return boolean
function CustomParticipantTable.isPureSolo(sections)
	return Array.all(sections, function(section) return Array.all(section.entries, function(entry)
		return entry.opponent.type == Opponent.solo
	end) end)
end

---@return Html?
function CustomParticipantTable:createSoloFactionTable()
	local config = self.config

	if not config.display then return end

	local factioNumbers = self:_getFactionNumbers()

	local factionColumns = Array.copy(Faction.coreFactions)

	if config.displayRandomColumn or config.displayRandomColumn == nil and factioNumbers.r > 0 then
		table.insert(factionColumns, Faction.read('r'))
	end

	if config.displayUnknownColumn or
		config.displayUnknownColumn == nil and factioNumbers[Faction.defaultFaction] > 0 then

		table.insert(factionColumns, Faction.defaultFaction)
	end

	if config.displayMultipleFactionColumn or
		config.displayMultipleFactionColumn == nil and factioNumbers.m > 0 then

		table.insert(factionColumns, Faction.read('m'))
	end

	local colSpan = #factionColumns

	self.display = mw.html.create('div')
		:addClass('participantTable participantTable-faction')
		:css('grid-template-columns', 'repeat(' .. colSpan .. ', 1fr)')
		:css('width', (colSpan * config.soloColumnWidth) .. 'px')
		:node(self:_displayHeader(factionColumns, factioNumbers))

	Array.forEach(self.sections, function(section) self:_displaySoloFactionTableSection(section, factionColumns) end)

	return mw.html.create('div')
		:addClass('table-responsive')
		:node(self.display)
end

---@return table
function CustomParticipantTable:_getFactionNumbers()
	local calculatedNumbers = {}

	Array.forEach(self.sections, function(section)
		section.entries = section.config.onlyNotable and self.filterOnlyNotables(section.entries) or section.entries

		Array.forEach(section.entries, function(entry)
			local faction = entry.opponent.players[1].faction or Faction.defaultFaction
			--if we have defaultFaction push it into the entry too
			entry.opponent.players[1].faction = faction
			calculatedNumbers[faction] = (calculatedNumbers[faction] or 0) + 1
			if entry.dq then
				calculatedNumbers[faction .. 'Dq'] = (calculatedNumbers[faction .. 'Dq'] or 0) + 1
			end
		end)
	end)

	local factionNumbers = {}
	for _, faction in pairs(Faction.getFactions()) do
		factionNumbers[faction] = calculatedNumbers[faction] or 0
		factionNumbers[faction .. 'Display'] = self.config.manualFactionCounts[faction] or
			(factionNumbers[faction] - (calculatedNumbers[faction .. 'Dq'] or 0))
	end

	return factionNumbers
end

---@param factionColumns table
---@param factioNumbers table
---@return Html
function CustomParticipantTable:_displayHeader(factionColumns, factioNumbers)
	local config = self.config
	local header = mw.html.create('div'):addClass('participantTable-row')

	Array.forEach(factionColumns, function(faction)
		local parts = Array.extend(
			faction ~= Faction.defaultFaction and Faction.Icon{faction = faction} or nil,
			' ' .. Faction.toName(faction),
			config.showCountByFaction and " ''(" .. factioNumbers[faction .. 'Display'] .. ")''" or nil
		)

		header:tag('div')
			:addClass('participantTable-faction-header participantTable-entry')
			:addClass(Faction.bgClass(faction))
			:tag('div')
				:wikitext(table.concat(parts))
	end)

	return header
end

---@param section WarcraftParticipantTableSection
---@param factionColumns table
function CustomParticipantTable:_displaySoloFactionTableSection(section, factionColumns)
	local sectionEntryCount = #Array.filter(section.entries, function(entry) return not entry.dq end)

	self.display:node(self.newSectionNode():node(self:sectionTitle(section, sectionEntryCount)))

	if Table.isEmpty(section.entries) then
		self.display:node(self.newSectionNode():node(self:tbd()))
		return
	end

	-- Group entries by faction
	local _, byFaction = Array.groupBy(section.entries, function(entry) return entry.opponent.players[1].faction end)

	-- Find the faction with the most players
	local maxFactionLength = Array.max(
		Array.map(factionColumns, function(faction) return #(byFaction[faction] or {}) end)
	) or 0

	Array.forEach(Array.range(1, maxFactionLength), function(rowIndex)
		local sectionNode = self.newSectionNode()
		Array.forEach(factionColumns, function(faction)
			local entry = byFaction[faction] and byFaction[faction][rowIndex]
			sectionNode:node(
				entry and self:displayEntry(entry, {showFaction = false}) or
				mw.html.create('div'):addClass('participantTable-entry')
			)
		end)
		self.display:node(sectionNode)
	end)
end

return CustomParticipantTable
