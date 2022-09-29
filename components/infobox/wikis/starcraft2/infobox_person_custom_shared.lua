---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/Custom/Shared
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--Shared functions between SC2 person infoboxes (Player/Commentator and MapMaker)

local CleanRace = require('Module:CleanRace')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local RaceIcon = require('Module:RaceIcon').getBigIcon
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

--race stuff tables
local _RACE_DATA = {
	p = {'Protoss'},
	pt = {'Protoss', 'Terran'},
	pz = {'Protoss', 'Zerg'},
	t = {'Terran'},
	tp = {'Terran', 'Protoss'},
	tz = {'Terran', 'Zerg'},
	z = {'Zerg'},
	zt = {'Zerg', 'Terran'},
	zp = {'Zerg', 'Protoss'},
	r = {'Random'},
	a = {'Protoss', 'Terran', 'Zerg'},
}
local _RACE_ALL = 'All'
local _RACE_ALL_SHORT = 'a'

--role stuff tables
local _ROLES = {
	['admin'] = 'Admin', ['analyst'] = 'Analyst', ['coach'] = 'Coach',
	['commentator'] = 'Commentator', ['caster'] = 'Commentator',
	['expert'] = 'Analyst', ['host'] = 'Host', ['streamer'] = 'Streamer',
	['interviewer'] = 'Interviewer', ['journalist'] = 'Journalist',
	['manager'] = 'Manager', ['player'] = 'Player',
	['map maker'] = 'Map maker', ['mapmaker'] = 'Map maker',
	['observer'] = 'Observer', ['photographer'] = 'Photographer',
	['tournament organizer'] = 'Organizer', ['organizer'] = 'Organizer',
}
local _CLEAN_OTHER_ROLES = {
	['blizzard'] = 'Blizzard', ['coach'] = 'Coach', ['staff'] = 'false',
	['content producer'] = 'Content producer', ['streamer'] = 'false',
}

local _MILITARY_DATA = {
	starting = {category = 'Persons waiting for Military Duty', storeValue = 'pending'},
	ongoing = {category = 'Persons on Military Duty', storeValue = 'ongoing'},
	fulfilled = {category = 'Persons that completed their Military Duty', storeValue = 'fulfilled'},
	exempted = {category = 'Persons exempted from Military Duty', storeValue = 'exempted'},
}
_MILITARY_DATA.pending = _MILITARY_DATA.starting
_MILITARY_DATA.started = _MILITARY_DATA.ongoing
_MILITARY_DATA.ending = _MILITARY_DATA.ongoing

local _raceData
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
	CustomPerson.getRaceData(_args.race or 'unknown')
	local raceIcon = RaceIcon({'alt_' .. _raceData.race})
	local name = _args.id or _PAGENAME

	return raceIcon .. '&nbsp;' .. name
end

function CustomPerson.getRaceData(race, asCategory)
	race = string.lower(race)
	race = CleanRace[race] or race
	local raceTable = _RACE_DATA[race]

	local faction, faction2
	if race == _RACE_ALL_SHORT then
		faction = _RACE_ALL
	else
		faction = (raceTable or {})[1]
		faction2 = (raceTable or {})[2]
	end

	local display
	if not raceTable and race ~= 'unknown' then
		display = '[[Category:InfoboxRaceError]]<strong class="error">' ..
			mw.text.nowiki('Error: Invalid Race') .. '</strong>'
	else
		if asCategory then
			for raceIndex, raceValue in ipairs(raceTable or {}) do
				raceTable[raceIndex] = ':Category:' .. raceValue .. ' Players|' .. raceValue .. ']]'
					.. '[[Category:' .. raceValue .. ' Players'
			end
		end
		if raceTable then
			display = '[[' .. table.concat(raceTable, ']],&nbsp;[[') .. ']]'
		end
	end

	_raceData = {
		race = race,
		faction = faction or '',
		faction2 = faction2 or '',
		display = display,
	}

	return display
end

function CustomPerson.adjustLPDB(_, lpdbData)
	local extradata = lpdbData.extradata or {}
	extradata.race = _raceData.race
	extradata.faction = _raceData.faction
	extradata.faction2 = _raceData.faction2
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
		for key, item in pairs(_MILITARY_DATA) do
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
	local category = _ROLES[role]
	local store = category or _CLEAN_OTHER_ROLES[role] or _args.defaultPersonType
	if category == 'Map Maker' then
		category = 'Mapmaker'
	end

	return {store = store, category = category or _args.defaultPersonType}
end

return CustomPerson
