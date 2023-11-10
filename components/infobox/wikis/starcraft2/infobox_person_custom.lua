---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--Extends the Infobox/Person class with shared functions between SC2 person infoboxes

local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Person = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local RACE_ALL = 'All'
local RACE_ALL_SHORT = 'a'
local RACE_ALL_ICON = '[[File:RaceIcon All.png|30px|link=]]'

--role stuff tables
local ROLES = {
	['admin'] = 'Admin', ['analyst'] = 'Analyst', ['coach'] = 'Coach',
	['commentator'] = 'Commentator', ['caster'] = 'Commentator',
	['expert'] = 'Analyst', ['host'] = 'Host', ['streamer'] = 'Streamer',
	['interviewer'] = 'Interviewer', ['journalist'] = 'Journalist',
	['manager'] = 'Manager', ['player'] = 'Player',
	['map maker'] = 'Map maker', ['mapmaker'] = 'Map maker',
	['observer'] = 'Observer', ['photographer'] = 'Photographer',
	['tournament organizer'] = 'Organizer', ['organizer'] = 'Organizer',
}
local CLEAN_OTHER_ROLES = {
	['blizzard'] = 'Blizzard', ['coach'] = 'Coach', ['staff'] = 'false',
	['content producer'] = 'Content producer', ['streamer'] = 'false',
}

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
	extradata.role = args.role
	extradata.role2 = args.role2
	extradata.militaryservice = self:military(args.military).storeValue
	extradata.activeplayer = not CustomPerson:getStatusToStore(args)
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

---@param args table
---@return string?
function CustomPerson:getStatusToStore(args)
	if args.death_date then
		return 'Deceased'
	elseif args.retired then
		return 'Retired'
	end
end

---@param args table
---@return {store: string, category: string}
function CustomPerson:getPersonType(args)
	if args.isplayer == 'true' then
		return {store = 'Player', category = 'Player'}
	end

	local role = args.role or args.occupation or args.defaultPersonType
	role = string.lower(role or '')
	local category = ROLES[role]
	local store = category or CLEAN_OTHER_ROLES[role] or args.defaultPersonType
	if category == ROLES['map maker'] then
		category = 'Mapmaker'
	end

	return {store = store, category = category or args.defaultPersonType}
end

return CustomPerson
