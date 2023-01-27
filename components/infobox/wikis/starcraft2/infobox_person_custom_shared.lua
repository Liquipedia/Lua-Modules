---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/Custom/Shared
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--Shared functions between SC2 person infoboxes (Player/Commentator and MapMaker)

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local RaceIcon = require('Module:RaceIcon').getBigIcon
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local RACE_ALL = 'All'
local RACE_ALL_SHORT = 'a'
local RACE_ALL_ORDER = 'ptz'
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

local _statusStore
local _militaryStore
local _args

local _PAGENAME = mw.title.getCurrentTitle().prefixedText

local CustomPerson = {}

function CustomPerson.setArgs(args)
	_args = args
end

function CustomPerson.shouldStoreData()
	if
		Logic.readBool(_args.disable_lpdb) or Logic.readBool(_args.disable_storage)
		or Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
		or not Namespace.isMain()
	then
		Variables.varDefine('disable_LPDB_storage', 'true')
		return false
	end
	return true
end

function CustomPerson.nameDisplay()
	local raceData = CustomPerson.readFactions(_args.race or Faction.defaultFaction)

	local raceIcons
	if isAll then
		raceIcons = RACE_ALL_ICON
	else
		raceIcons = table.concat(Array.map(raceData.factions, function(faction)
			return Faction.Icon{faction = faction, size = 'large'}
		end))
	end

	local name = _args.id or _PAGENAME

	return raceIcons .. '&nbsp;' .. name
end

function CustomPerson.getRaceData(race, asCategory)
	local factions = CustomPerson.readFactions(race).factions

	local display = Array.map(Array.map(factions, Faction.toName), function(faction)
		if asCategory then
			return '[[:Category:' .. faction .. ' Players|' .. faction .. ']]'
		end
		return '[[' .. faction .. ']]'
	end)

	return table.concat(display, ',&nbsp;')
end

function CustomPerson.readFactions(input)
	if input == RACE_ALL or input == RACE_ALL_SHORT then
		input = RACE_ALL_ORDER
	end

	local factions = Faction.readMultiFaction(input, {alias = false})

	local isAll = false
	-- check if factions == Faction.coreFactions modulo order
	if #factions == Table.size(Faction.coreFactions) then
		local coreFactionsInFactions = Array.filter(
			Faction.coreFactions,
			function(faction) return Table.includes(factions, faction) end
		)

		if #coreFactionsInFactions == #factions then
			isAll = true
		end
	end

	factions = Array.map(factions, Faction.toName)

	return {isAll = isAll, factions = factions}
end

function CustomPerson.adjustLPDB(_, lpdbData)
	local extradata = lpdbData.extradata or {}

	local raceData = CustomPerson.readFactions(_args.race)

	extradata.race = raceData.isAll and RACE_ALL_SHORT or raceData.factions[1]
	extradata.faction = raceData.isAll and RACE_ALL or raceData.factions[1]
	extradata.faction2 = (not raceData.isAll) and raceData.factions[1] or nil
	extradata.lc_id = string.lower(_PAGENAME)
	extradata.teamname = _args.team
	extradata.role = _args.role
	extradata.role2 = _args.role2
	extradata.militaryservice = _militaryStore
	extradata.activeplayer = (not _statusStore) and Variables.varDefault('isActive', '') or ''

	if Variables.varDefault('racecount') then
		extradata.racehistorical = true
		extradata.factionhistorical = true
	end

	lpdbData.extradata = extradata

	return lpdbData
end

function CustomPerson.military(military)
	if military and military ~= 'false' then
		local display = military
		local militaryCategory = ''
		military = string.lower(military)
		for key, item in pairs(MILITARY_DATA) do
			if String.contains(military, key) then
				militaryCategory = '[[Category:' .. item.category .. ']]'
				_militaryStore = item.storeValue
				break
			end
		end

		return display .. militaryCategory
	end
end

function CustomPerson.getStatusToStore()
	if _args.death_date then
		_statusStore = 'Deceased'
	elseif _args.retired then
		_statusStore = 'Retired'
	elseif
		(not Logic.readBool(_args.isplayer)) and
		string.lower(_args.role or _args.defaultPersonType) ~= 'player'
	then
		_statusStore = 'not player'
	end
	return _statusStore
end

function CustomPerson.getPersonType()
	if _args.isplayer == 'true' then
		return {store = 'Player', category = 'Player'}
	end

	local role = _args.role or _args.occupation or _args.defaultPersonType
	role = string.lower(role or '')
	local category = ROLES[role]
	local store = category or CLEAN_OTHER_ROLES[role] or _args.defaultPersonType
	if category == ROLES['map maker'] then
		category = 'Mapmaker'
	end

	return {store = store, category = category or _args.defaultPersonType}
end

return CustomPerson
