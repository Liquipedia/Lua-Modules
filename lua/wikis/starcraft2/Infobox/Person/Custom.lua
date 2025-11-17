---
-- @Liquipedia
-- page=Module:Infobox/Person/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Person = Lua.import('Module:Infobox/Person')

local STATUS_ACTIVE = 'Active'
local RACE_ALL = 'All'
local RACE_ALL_SHORT = 'a'
local RACE_ALL_ICON = '[[File:RaceIcon All.png|30px|link=]]'

local MILITARY_DATA = {
	starting = {category = 'Persons waiting for Military Duty', storeValue = 'pending'},
	ongoing = {category = 'Persons on Military Duty', storeValue = 'ongoing'},
	fulfilled = {category = 'Persons that completed their Military Duty', storeValue = 'fulfilled'},
	exempted = {category = 'Persons exempted from Military Duty', storeValue = 'exempted'},
}
MILITARY_DATA.pending = MILITARY_DATA.starting
MILITARY_DATA.started = MILITARY_DATA.ongoing
MILITARY_DATA.ending = MILITARY_DATA.ongoing

---@class SC2CustomPerson: Person
local CustomPerson = Class.new(Person)

---@param args table
---@return boolean
function CustomPerson:shouldStoreData(args)
	if
		Logic.readBool(args.disable_lpdb) or Logic.readBool(args.disable_storage)
		or Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
		or not Namespace.isMain()
	then
		Variables.varDefine('disable_LPDB_storage', 'true')
		return false
	end
	return true
end

---@param args table
---@return string
function CustomPerson:nameDisplay(args)
	local raceData = self:readFactions(args.race or Faction.defaultFaction)

	local raceIcons
	if raceData.isAll then
		raceIcons = RACE_ALL_ICON
	else
		raceIcons = table.concat(Array.map(raceData.factions, function(faction)
			return Faction.Icon{faction = faction, size = 'large'}
		end))
	end

	local name = args.id or self.pagename

	return raceIcons .. '&nbsp;' .. name
end

---@param race string?
---@param asCategory boolean?
---@return string
function CustomPerson:getRaceData(race, asCategory)
	local factions = self:readFactions(race).factions

	return table.concat(Array.map(factions, function(faction)
		if asCategory then
			return '[[:Category:' .. faction .. ' Players|' .. faction .. ']]'
		end
		return '[[' .. faction .. ']]'
	end) or {}, ',&nbsp;')
end

---@param input string?
---@return {isAll: boolean, factions: string[]}
function CustomPerson:readFactions(input)
	local factions
	if input == RACE_ALL or input == RACE_ALL_SHORT then
		factions = Array.copy(Faction.coreFactions)
	else
		factions = Faction.readMultiFaction(input, {alias = false})
	end

	local isAll = Table.deepEquals(Array.sortBy(factions, FnUtil.identity), Faction.coreFactions)

	factions = Array.map(factions, Faction.toName)

	return {isAll = isAll, factions = factions}
end

---@param lpdbData table<string, string|number|table|nil>
---@param args table
---@param personType string
---@return table<string, string|number|table|nil>
function CustomPerson:adjustLPDB(lpdbData, args, personType)
	local extradata = lpdbData.extradata or {}

	local raceData = self:readFactions(args.race)

	extradata.race = raceData.isAll and RACE_ALL_SHORT or raceData.factions[1]
	extradata.faction = raceData.isAll and RACE_ALL or raceData.factions[1]
	extradata.faction2 = (not raceData.isAll) and raceData.factions[2] or nil
	extradata.lc_id = string.lower(self.pagename)
	extradata.teamname = args.team
	extradata.militaryservice = self:military(args.military).storeValue
	extradata.activeplayer = CustomPerson:getStatusToStore(args) == STATUS_ACTIVE
		and CustomPerson._isPlayer(args)
		and Variables.varDefault('isActive', '') or ''

	if Variables.varDefault('racecount') then
		extradata.racehistorical = true
		extradata.factionhistorical = true
	end

	lpdbData.extradata = extradata

	return lpdbData
end

---@param args table
---@return boolean
function CustomPerson._isPlayer(args)
	return not Logic.readBool(args.isplayer) and
		string.lower(args.role or args.defaultPersonType) ~= 'player'
end

---@param military string?
---@return {category: string?, storeValue: string?}
function CustomPerson:military(military)
	if not Logic.readBool(military) then return {} end
	---@cast military -nil

	military = military:lower()
	for key, data in pairs(MILITARY_DATA) do
		if String.contains(military, key) then return data end
	end

	return {}
end

return CustomPerson
