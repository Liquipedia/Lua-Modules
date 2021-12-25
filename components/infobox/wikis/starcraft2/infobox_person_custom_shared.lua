---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/Custom/Shared
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--Shared functions between SC2 person infoboxes (Player/Commentator and MapMaker)

local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local RaceIcon = require('Module:RaceIcon').getBigIcon
local CleanRace = require('Module:CleanRace')
local Logic = require('Module:Logic')

--race stuff tables
local _FACTION1 = {
	['p'] = 'Protoss', ['pt'] = 'Protoss', ['pz'] = 'Protoss',
	['t'] = 'Terran', ['tp'] = 'Terran', ['tz'] = 'Terran',
	['z'] = 'Zerg', ['zt'] = 'Zerg', ['zp'] = 'Zerg',
	['r'] = 'Random', ['a'] = 'All'
}
local _FACTION2 = {
	['pt'] = 'Terran', ['pz'] = 'Zerg',
	['tp'] = 'Protoss', ['tz'] = 'Zerg',
	['zt'] = 'Terran', ['zp'] = 'Protoss'
}

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
		_args.disable_smw == 'true' or _args.disable_lpdb == 'true' or _args.disable_storage == 'true'
		or Variables.varDefault('disable_SMW_storage', 'false') == 'true'
		or mw.title.getCurrentTitle().nsText ~= ''
	then
		Variables.varDefine('disable_SMW_storage', 'true')
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

function CustomPerson.getRaceData(race)
	race = string.lower(race)
	race = CleanRace[race] or race
	local display = CustomPerson.raceDisplayLookupTable[race]
	if not display and race ~= 'unknown' then
		display = '[[Category:InfoboxRaceError]]<strong class="error">' ..
			mw.text.nowiki('Error: Invalid Race') .. '</strong>'
	end

	_raceData = {
		race = race,
		faction = _FACTION1[race] or '',
		faction2 = _FACTION2[race] or '',
		display = display
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
		military = string.lower(military)
		local militaryCategory = ''
		if String.contains(military, 'starting') or String.contains(military, 'pending') then
			militaryCategory = '[[Category:Persons waiting for Military Duty]]'
			_militaryStore = 'pending'
		elseif
			String.contains(military, 'ending') or String.contains(military, 'started')
			or String.contains(military, 'ongoing')
		then
			militaryCategory = '[[Category:Persons on Military Duty]]'
			_militaryStore = 'ongoing'
		elseif String.contains(military, 'fulfilled') then
			militaryCategory = '[[Category:Persons expleted Military Duty]]'
			_militaryStore = 'fulfilled'
		elseif String.contains(military, 'exempted') then
			militaryCategory = '[[Category:Persons exempted from Military Duty]]'
			_militaryStore = 'exempted'
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
	role = string.lower(role)
	local category = _ROLES[role]
	local store = category or _CLEAN_OTHER_ROLES[role] or _args.defaultPersonType
	if category == 'Map Maker' then
		category = 'Mapmaker'
	end

	return {store = store, category = category or _args.defaultPersonType}
end

return CustomPerson
