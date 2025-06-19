---
-- @Liquipedia
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

---@class StormgateParticipantTableConfig: ParticipantTableConfig
---@field displayUnknownColumn boolean?
---@field displayRandomColumn boolean?
---@field showCountByFaction boolean
---@field isRandomEvent boolean
---@field isQualified boolean?
---@field manualFactionCounts table<string, number?>
---@field soloColumnWidth number
---@field soloAsFactionTable boolean

---@class StormgateParticipantTableEntry: ParticipantTableEntry
---@field isQualified boolean?
---@field opponent StormgateStandardOpponent

---@class StormgateParticipantTableSection: ParticipantTableSection
---@field entries StormgateParticipantTableEntry[]

---@class StormgateParticipantTable: ParticipantTable
---@field config StormgateParticipantTableConfig
---@field isPureSolo boolean
---@field _displaySoloFactionTableSection function
---@field _displayHeader function
---@field _getFactionNumbers function

local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StormgateParticipantTable = {}

---@param frame Frame
---@return Html?
function StormgateParticipantTable.run(frame)
	local participantTable = ParticipantTable(frame) --[[@as StormgateParticipantTable]]

	participantTable.readConfig = StormgateParticipantTable.readConfig
	participantTable.readEntry = StormgateParticipantTable.readEntry
	participantTable.adjustLpdbData = StormgateParticipantTable.adjustLpdbData
	participantTable._displaySoloFactionTableSection = StormgateParticipantTable._displaySoloFactionTableSection
	participantTable._displayHeader = StormgateParticipantTable._displayHeader
	participantTable._getFactionNumbers = StormgateParticipantTable._getFactionNumbers
	participantTable.setCustomPageVariables = StormgateParticipantTable.setCustomPageVariables

	participantTable:read():store()

	if StormgateParticipantTable.isPureSolo(participantTable.sections) and participantTable.config.soloAsFactionTable then
		participantTable.create = StormgateParticipantTable.createSoloFactionTable
	end

	return participantTable:create()
end

---@param args table
---@param parentConfig StormgateParticipantTableConfig?
---@return StormgateParticipantTableConfig
function StormgateParticipantTable.readConfig(args, parentConfig)
	local config = ParticipantTable.readConfig(args, parentConfig) --[[@as StormgateParticipantTableConfig]]
	parentConfig = parentConfig or {}

	config.displayUnknownColumn = Logic.readBoolOrNil(args.unknowncolumn)
	config.displayRandomColumn = Logic.readBoolOrNil(args.randomcolumn)
	config.showCountByFaction = Logic.readBool(args.showCountByFaction or args.count)
	config.isRandomEvent = Logic.nilOr(Logic.readBoolOrNil(args.is_random_event), parentConfig.isRandomEvent)
	config.isQualified = Logic.nilOr(Logic.readBoolOrNil(args.isQualified), parentConfig.isQualified)
	config.sortPlayers = true
	--only relevant for solo case since there we need columnWidth in px since colSpan is calculated dynamically
	config.soloColumnWidth = tonumber(args.entrywidth) or config.showTeams and 212 or 156

	config.manualFactionCounts = {}
	Array.forEach(Faction.knownFactions, function(faction)
		config.manualFactionCounts[faction] = tonumber(args[Faction.toName(faction):lower()])
	end)

	config.soloAsFactionTable = not Logic.readBool(args.soloNotAsFactionTable)

	return config
end

---@param sectionArgs table
---@param key string|number
---@param index number
---@param config StormgateParticipantTableConfig
---@return StormgateParticipantTableEntry
function StormgateParticipantTable:readEntry(sectionArgs, key, index, config)
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
		faction = valueFromArgs('faction'),
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
	}
end

---@param lpdbData table
---@param entry StormgateParticipantTableEntry
---@param config StormgateParticipantTableConfig
function StormgateParticipantTable:adjustLpdbData(lpdbData, entry, config)
	if config.isRandomEvent then
		lpdbData.opponentplayers.p1faction = Faction.read('r')
	end

	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	local isQualified = entry.isQualified or config.isQualified

	lpdbData.extradata.seriesnumber = seriesNumber and string.format('%05d', seriesNumber) or nil
	lpdbData.extradata.isqualified = tostring(isQualified)

	lpdbData.qualified = isQualified and 1 or nil
end

---@param sections StormgateParticipantTableSection[]
---@return boolean
function StormgateParticipantTable.isPureSolo(sections)
	return Array.all(sections, function(section) return Array.all(section.entries, function(entry)
		return entry.opponent.type == Opponent.solo
	end) end)
end

---@return Html?
function StormgateParticipantTable:createSoloFactionTable()
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
function StormgateParticipantTable:_getFactionNumbers()
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
function StormgateParticipantTable:_displayHeader(factionColumns, factioNumbers)
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

---@param section StormgateParticipantTableSection
---@param factionColumns table
function StormgateParticipantTable:_displaySoloFactionTableSection(section, factionColumns)
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
				entry and self:displayEntry(entry, {hideFaction = true}) or
				mw.html.create('div'):addClass('participantTable-entry')
			)
		end)
		self.display:node(sectionNode)
	end)
end

---@param entry StormgateParticipantTableEntry
---@param config StormgateParticipantTableConfig
function StormgateParticipantTable:setCustomPageVariables(entry, config)
	if config.isRandomEvent then
		Variables.varDefine(entry.opponent.players[1].displayName .. '_faction', Faction.read('r'))
	end
end

return StormgateParticipantTable
