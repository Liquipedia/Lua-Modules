---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/MapMaker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CleanRace = require('Module:CleanRace')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local RaceIcon = require('Module:RaceIcon')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MapMaker = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomMapMaker = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomMapMaker.run(frame)
	local player = Person(frame)
	_args = player.args
	PersonSc2.setArgs(_args)

	player.shouldStoreData = PersonSc2.shouldStoreData
	player.getStatusToStore = PersonSc2.getStatusToStore
	player.adjustLPDB = PersonSc2.adjustLPDB
	player.getPersonType = PersonSc2.getPersonType
	player.nameDisplay = PersonSc2.nameDisplay

	player.calculateEarnings = CustomMapMaker.calculateEarnings
	player.createBottomContent = CustomMapMaker.createBottomContent
	player.createWidgetInjector = CustomMapMaker.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {PersonSc2.getRaceData(_args.race or 'unknown')}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then
		if String.isNotEmpty(_args.maps_ladder) or String.isNotEmpty(_args.maps_special) then
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
		Cell{name = 'Military Service', content = {PersonSc2.military(_args.military)}},
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


return CustomMapMaker
