---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Lib/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local Util = {}

---@param section ParticipantTableSection
function Util.backFillEntries(section)
	local config = section.config
	Array.forEach(section.entries, function(entry)
		entry.sortName = entry.sortName or Opponent.toName(entry.opponent)
		entry.opponent = entry.isResolved and entry.opponent or Opponent.resolve(entry.opponent, config.resolveDate, {
			syncPlayer = config.syncPlayers,
			overwritePageVars = true,
		})
		entry.name = entry.name or Opponent.toName(entry.opponent)
		entry.isResolved = true
	end)
end

---@param section ParticipantTableSection
function Util.sortOpponents(section)
	if not section.config.sortOpponents then return end
	Array.sortInPlaceBy(section.entries, function(entry)
		return entry.sortName:lower()
	end)
end

---@param sections ParticipantTableSection[]
---@return boolean
function Util.hasSeed(sections)
	return Array.any(sections, function(section)
		return Array.any(section.entries, function(entry)
			return entry.seed ~= nil
		end)
	end)
end

---@param sections ParticipantTableSection[]
---@return ParticipantTableSection[]
function Util.filterOnlyNotables(sections)
	local function filter(entries)
		return Array.filter(entries, function(entry)
			return Array.any(entry.opponent.players or {}, function(player)
				return Logic.isNotEmpty(player.pageName) and PlayerExt.fetchPlayerFlag(player.pageName) ~= nil
			end)
		end)
	end

	return Array.map(sections, function(section)
		if section.config.onlyNotable then
			section.entries = filter(section.entries)
		end
		return section
	end)
end

---@param sections ParticipantTableSection[]
---@param config ParticipantTableConfig
---@return table<string, integer>
function Util.getFactionNumbers(sections, config)
	local calculatedNumbers = {}

	Array.forEach(sections, function(section)
		Array.forEach(section.entries, function(entry)
			local faction = entry.opponent.players[1].faction or Faction.defaultFaction
			calculatedNumbers[faction] = (calculatedNumbers[faction] or 0) + 1
			if entry.dq then
				calculatedNumbers[faction .. 'Dq'] = (calculatedNumbers[faction .. 'Dq'] or 0) + 1
			end
		end)
	end)

	local factionNumbers = {}
	for _, faction in pairs(Faction.getFactions()) do
		factionNumbers[faction] = calculatedNumbers[faction] or 0
		factionNumbers[faction .. 'Display'] = config.manualFactionCounts[faction] or
			(factionNumbers[faction] - (calculatedNumbers[faction .. 'Dq'] or 0))
	end

	return factionNumbers
end

---@param config ParticipantTableConfig
---@param factionNumbers table<string, integer>
---@return string[]
function Util.getFactionColumns(config, factionNumbers)

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

	return factionColumns
end

---@param sections ParticipantTableSection[]
---@param config ParticipantTableConfig
---@return boolean
function Util.shouldDisplayAsFactionTable(sections, config)
	if not config.soloAsFactionTable then
		return false
	end
	return Array.all(sections, function(section)
		return Array.all(section.entries, function(entry)
			return entry.opponent.type == Opponent.solo
		end)
	end)
end

return Util
