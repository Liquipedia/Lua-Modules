---
-- @Liquipedia
-- page=Module:ParticipantTable/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Faction = Lua.import('Module:Faction')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local ParticipantTable = Lua.import('Module:ParticipantTable/Base')
local Variables = Lua.import('Module:Variables')

local FactionTable = Lua.import('Module:Features/ParticipantTable/Components/FactionTable')

---@class StarcraftParticipantTable: ParticipantTable
---@operator call(Frame): StarcraftParticipantTable
---@field config ParticipantTableConfig
---@field sections StarcraftParticipantTableSection[]
local StarcraftParticipantTable = Class.new(ParticipantTable)

---@param frame Frame
---@return VNode?
function StarcraftParticipantTable.run(frame)
	return StarcraftParticipantTable(frame):read():store():create()
end

---@param sectionArgs table
---@param key string|number
---@param index number
---@param config ParticipantTableConfig
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
		seed = valueFromArgs('seed'),
		faction = valueFromArgs('race') or valueFromArgs('faction'),
	}

	assert(Opponent.isType(opponentArgs.type), 'Invalid opponent type for "' .. sectionArgs[key] .. '"')

	opponentArgs.seed = tonumber(opponentArgs.seed)
	if opponentArgs.seed then
		self.hasSeeds = true
	end

	--unset wiki var for random events to not read players as random if prize pool already sets them as random
	if config.isRandomEvent and opponentArgs.type == Opponent.solo then
		Variables.varDefine(opponentArgs.name .. '_faction', '')
	end

	local opponent = Opponent.readOpponentArgs(opponentArgs)

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
		inputIndex = index,
		seed = opponentArgs.seed,
	}
end

---@param lpdbData table
---@param entry StarcraftParticipantTableEntry
---@param config ParticipantTableConfig
function StarcraftParticipantTable:adjustLpdbData(lpdbData, entry, config)
	if config.isRandomEvent then
		lpdbData.opponentplayers.p1faction = Faction.read('r')
	end

	lpdbData.extradata.mod = Variables.varDefault('tournament_mod')
end

---@return boolean
function StarcraftParticipantTable:isPureSolo()
	return Array.all(self.sections, function(section) return Array.all(section.entries, function(entry)
		return entry.opponent.type == Opponent.solo
	end) end)
end

---@return VNode?
function StarcraftParticipantTable:create()
	if self:isPureSolo() and self.config.soloAsFactionTable then
		return self:createSoloFactionTable()
	end
	return ParticipantTable.create(self)
end

---@return VNode?
function StarcraftParticipantTable:createSoloFactionTable()
	local config = self.config

	if not config.display then return end

	local factionNumbers = self:_getFactionNumbers()

	local factionColumns
	if config.displayRandomColumn or
		not config.isRandomEvent and config.displayRandomColumn == nil and factionNumbers.rDisplay > 0 then

		factionColumns = Array.copy(Faction.knownFactions)
	else
		factionColumns = Array.copy(Faction.coreFactions)
	end

	if config.displayUnknownColumn or
		config.displayUnknownColumn == nil and factionNumbers[Faction.defaultFaction .. 'Display'] > 0 then

		table.insert(factionColumns, Faction.defaultFaction)
	end


	if config.displayMultipleFactionColumn or
		config.displayMultipleFactionColumn == nil and factionNumbers.mDisplay and factionNumbers.mDisplay > 0 then

		table.insert(factionColumns, Faction.read('m'))
	end

	return FactionTable{
		config = self.config,
		factionColumns = factionColumns,
		factionNumbers = factionNumbers,
		sections = self.sections,
	}
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

---@param entry StarcraftParticipantTableEntry
---@param config ParticipantTableConfig
function StarcraftParticipantTable:setCustomPageVariables(entry, config)
	if config.isRandomEvent then
		Variables.varDefine(entry.opponent.players[1].displayName .. '_faction', Faction.read('r'))
	end
end

return StarcraftParticipantTable
