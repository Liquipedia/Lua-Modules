---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/MapMaker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CleanRace = require('Module:CleanRace')
local Logic = require('Module:Logic')
local MapMaker = require('Module:Infobox/Person')
local Namespace = require('Module:Namespace')
local RaceIcon = require('Module:RaceIcon')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

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
local _RACE_DISPLAY = {
	['p'] = '[[Protoss]]',
	['pt'] = '[[Protoss]],&nbsp;[[Terran]]',
	['pz'] = '[[Protoss]],&nbsp;[[Zerg]]',
	['t'] = '[[Terran]]',
	['tp'] = '[[Terran]],&nbsp;[[Protoss]]',
	['tz'] = '[[Terran]],&nbsp;[[Zerg]]',
	['z'] = '[[Zerg]]',
	['zt'] = '[[Zerg]],&nbsp;[[Terran]]',
	['zp'] = '[[Zerg]],&nbsp;[[Protoss]]',
	['r'] = '[[Random]]',
	['a'] = '[[Protoss]],&nbsp;[[Terran]],&nbsp;[[Zerg]]',
}

--role stuff tables
local _ROLES = {
	['admin'] = 'Admin', ['analyst'] = 'Analyst', ['coach'] = 'Coach',
	['commentator'] = 'Commentator', ['caster'] = 'Commentator',
	['expert'] = 'Analyst', ['host'] = 'Host', ['streamer'] = 'Streamer',
	['interviewer'] = 'Interviewer', ['journalist'] = 'Journalist',
	['manager'] = 'Manager', ['player'] = 'Player',
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

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')

local CustomMapMaker = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomMapMaker.run(frame)
	local mapMaker = MapMaker(frame)
	_args = mapMaker.args

	mapMaker.shouldStoreData = CustomMapMaker.shouldStoreData
	mapMaker.getStatusToStore = CustomMapMaker.getStatusToStore
	mapMaker.adjustLPDB = CustomMapMaker.adjustLPDB
	mapMaker.getPersonType = CustomMapMaker.getPersonType

	mapMaker.nameDisplay = CustomMapMaker.nameDisplay
	mapMaker.createWidgetInjector = CustomMapMaker.createWidgetInjector

	return mapMaker:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return { Cell{name = 'Race', content = { _raceData.display }
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then
		if not(String.isEmpty(_args.maps_ladder) or String.isEmpty(_args.maps_special)) then
			return {
				Title{name = 'Achievements'},
				Cell{name = 'Ladder maps created', content = {_args.maps_ladder}},
				Cell{name = 'Non-ladder competitive maps created', content = {_args.maps_special}}
			}
		end
		return {}
	elseif
		id == 'history' and
		string.match(_args.retired or '', '%d%d%d%d')
	then
		table.insert(widgets, Cell{
				name = 'Retired',
				content = {_args.retired}
			})
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Military Service', content = { CustomMapMaker._military(_args.military) }},
	}
end

function CustomMapMaker:createWidgetInjector()
	return CustomInjector()
end

function CustomMapMaker:nameDisplay()
	CustomMapMaker._getRaceData(_args.race or 'unknown')
	local raceIcon = RaceIcon.getBigIcon({'alt_' .. _raceData.race})
	local name = _args.id or self.pagename

	return raceIcon .. '&nbsp;' .. name
end

function CustomMapMaker._getRaceData(race)
	race = string.lower(race)
	race = CleanRace[race] or race
	local display = _RACE_DISPLAY[race]
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
end

function CustomMapMaker:shouldStoreData()
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

function CustomMapMaker:adjustLPDB(lpdbData, _, personType)
	local extradata = {
		race = _raceData.race,
		faction = _raceData.faction,
		faction2 = _raceData.faction2,
		lc_id = string.lower(self.pagename),
		teamname = _args.team,
		role = _args.role,
		role2 = _args.role2,
		militaryservice = _militaryStore,
	}
	if Variables.varDefault('racecount') then
		extradata.racehistorical = true
		extradata.factionhistorical = true
	end

	lpdbData.extradata = Table.mergeInto(lpdbData.extradata, extradata)

	return lpdbData
end

function CustomMapMaker._military(military)
	if military and military ~= 'false' then
		local display = military
		military = string.lower(military)
		local militaryCategory = ''
		if String.contains(military, 'starting') or String.contains(military, 'pending') then
			militaryCategory = '[[Category:Mapmakers waiting for Military Duty]]'
			_militaryStore = 'pending'
		elseif
			String.contains(military, 'ending') or String.contains(military, 'started')
			or String.contains(military, 'ongoing')
		then
			militaryCategory = '[[Category:Mapmakers on Military Duty]]'
			_militaryStore = 'ongoing'
		elseif String.contains(military, 'fulfilled') then
			militaryCategory = '[[Category:Mapmakers expleted Military Duty]]'
			_militaryStore = 'fulfilled'
		elseif String.contains(military, 'exempted') then
			militaryCategory = '[[Category:Mapmakers exempted from Military Duty]]'
			_militaryStore = 'exempted'
		end

		return display .. militaryCategory
	end
end

function CustomMapMaker:getStatusToStore()
	if _args.death_date then
		_statusStore = 'Deceased'
	elseif _args.retired then
		_statusStore = 'Retired'
	elseif
		(not Logic.readBool(_args.isplayer)) and
		string.lower(_args.role or _args.occupation or 'map maker') ~= 'player'
	then
		_statusStore = 'not player'
	end
	return _statusStore
end

function CustomMapMaker:getPersonType()
	if _args.isplayer == 'true' then
		return { store = 'Player', category = 'Player' }
	end
	local role = _args.role or _args.occupation or 'map maker'
	role = string.lower(role)
	local category = _ROLES[role]
	local store = category or _CLEAN_OTHER_ROLES[role] or 'Map maker'
	if category == 'Map Maker' then
		category = 'Mapmaker'
	end

	return { store = store, category = category or 'Mapmaker' }
end

return CustomMapMaker
