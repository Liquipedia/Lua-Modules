---
-- @Liquipedia
-- page=Module:ParticipantTable/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Faction = Lua.import('Module:Faction')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

---@class StarcraftParticipantTableConfig: ParticipantTableConfig
---@field displayUnknownColumn boolean?
---@field displayRandomColumn boolean?
---@field showCountByFaction boolean
---@field isRandomEvent boolean
---@field isQualified boolean?
---@field manualFactionCounts table<string, number?>
---@field soloColumnWidth number
---@field soloAsFactionTable boolean

---@class StarcraftParticipantTableEntry: ParticipantTableEntry
---@field isQualified boolean?
---@field opponent StarcraftStandardOpponent

---@class StarcraftParticipantTableSection: ParticipantTableSection
---@field entries StarcraftParticipantTableEntry[]

---@class StarcraftParticipantTable: ParticipantTable
---@field config StarcraftParticipantTableConfig
---@field isPureSolo boolean
---@field _displaySoloFactionTableSection function
---@field _displayHeader function
---@field _getFactionNumbers function

local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StarcraftParticipantTable = {}

---@param frame Frame
---@return Html?
function StarcraftParticipantTable.run(frame)
	local participantTable = ParticipantTable(frame) --[[@as StarcraftParticipantTable]]

	participantTable.readConfig = StarcraftParticipantTable.readConfig
	participantTable.readEntry = StarcraftParticipantTable.readEntry
	participantTable.adjustLpdbData = StarcraftParticipantTable.adjustLpdbData
	participantTable._displaySoloFactionTableSection = StarcraftParticipantTable._displaySoloFactionTableSection
	participantTable._displayHeader = StarcraftParticipantTable._displayHeader
	participantTable._getFactionNumbers = StarcraftParticipantTable._getFactionNumbers
	participantTable.setCustomPageVariables = StarcraftParticipantTable.setCustomPageVariables

	participantTable:read():store()

	if StarcraftParticipantTable.isPureSolo(participantTable.sections) and participantTable.config.soloAsFactionTable then
		participantTable.create = StarcraftParticipantTable.createSoloFactionTable
	end

	return participantTable:create()
end

---@param args table
---@param parentConfig StarcraftParticipantTableConfig?
---@return StarcraftParticipantTableConfig
function StarcraftParticipantTable.readConfig(args, parentConfig)
	local config = ParticipantTable.readConfig(args, parentConfig) --[[@as StarcraftParticipantTableConfig]]
	parentConfig = parentConfig or {}

	config.displayUnknownColumn = Logic.readBoolOrNil(args.unknowncolumn)
	config.displayRandomColumn = Logic.readBoolOrNil(args.randomcolumn)
	config.showCountByFaction = Logic.readBool(args.showCountByRace or args.count)
	config.isRandomEvent = Logic.nilOr(Logic.readBoolOrNil(args.is_random_event), parentConfig.isRandomEvent)
	config.isQualified = Logic.nilOr(Logic.readBoolOrNil(args.isQualified), parentConfig.isQualified)
	config.sortPlayers = true
	--only relevant for solo case since there we need columnWidth in px since colSpan is calculated dynamically
	config.soloColumnWidth = tonumber(args.entrywidth) or config.showTeams and 212 or 156

	config.manualFactionCounts = {}
	Array.forEach(Faction.knownFactions, function(faction)
		config.manualFactionCounts[faction] = tonumber(args[Faction.toName(faction):lower()])
	end)

	config.soloAsFactionTable = not Logic.readBool(args.soloNotAsRaceTable)

	return config
end

---@param sectionArgs table
---@param key string|number
---@param index number
---@param config StarcraftParticipantTableConfig
---@return StarcraftParticipantTableEntry
function StarcraftParticipantTable:readEntry(sectionArgs, key, index, config)
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

	assert(Opponent.isType(opponentArgs.type), 'Invalid opponent type for "' .. sectionArgs[key] .. '"')

	--unset wiki var for random events to not read players as random if prize pool already sets them as random
	if config.isRandomEvent and opponentArgs.type == Opponent.solo then
		Variables.varDefine(opponentArgs.name .. '_faction', '')
	end

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
		isQualified = Logic.nilOr(Logic.readBoolOrNil(sectionArgs[key .. 'qualified']), config.isQualified),
		inputIndex = index,
	}
end

---@param lpdbData table
---@param entry StarcraftParticipantTableEntry
---@param config StarcraftParticipantTableConfig
function StarcraftParticipantTable:adjustLpdbData(lpdbData, entry, config)
	if config.isRandomEvent then
		lpdbData.opponentplayers.p1faction = Faction.read('r')
	end

	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	local isQualified = entry.isQualified or config.isQualified

	lpdbData.extradata.seriesnumber = seriesNumber and string.format('%05d', seriesNumber) or nil
	lpdbData.extradata.isqualified = tostring(isQualified)

	lpdbData.qualified = isQualified and 1 or nil
end

---@param sections StarcraftParticipantTableSection[]
---@return boolean
function StarcraftParticipantTable.isPureSolo(sections)
	return Array.all(sections, function(section) return Array.all(section.entries, function(entry)
		return entry.opponent.type == Opponent.solo
	end) end)
end

---@return Html?
function StarcraftParticipantTable:createSoloFactionTable()
	local config = self.config

	if not config.display then return end

	local factioNumbers = self:_getFactionNumbers()

	local factionColumns
	if not config.isRandomEvent and
		(config.displayRandomColumn or config.displayRandomColumn == nil and factioNumbers.rDisplay > 0) then

		factionColumns = Array.copy(Faction.knownFactions)
	else
		factionColumns = Array.copy(Faction.coreFactions)
	end

	if config.displayUnknownColumn or
		config.displayUnknownColumn == nil and factioNumbers[Faction.defaultFaction .. 'Display'] > 0 then

		table.insert(factionColumns, Faction.defaultFaction)
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
function StarcraftParticipantTable:_getFactionNumbers()
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
function StarcraftParticipantTable:_displayHeader(factionColumns, factioNumbers)
	local config = self.config
	local header = mw.html.create('div'):addClass('participantTable-row')

	Array.forEach(factionColumns, function(faction)
		local parts = Array.extend(
			config.isRandomEvent and Faction.Icon{faction = 'r'} or nil,
			faction ~= Faction.defaultFaction and Faction.Icon{faction = faction} or nil,
			' ' .. Faction.toName(faction),
			config.isRandomEvent and ' Main' or nil,
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

---@param section StarcraftParticipantTableSection
---@param factionColumns table
function StarcraftParticipantTable:_displaySoloFactionTableSection(section, factionColumns)
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

---@param entry StarcraftParticipantTableEntry
---@param config StarcraftParticipantTableConfig
function StarcraftParticipantTable:setCustomPageVariables(entry, config)
	if config.isRandomEvent then
		Variables.varDefine(entry.opponent.players[1].displayName .. '_faction', Faction.read('r'))
	end
end

return StarcraftParticipantTable
