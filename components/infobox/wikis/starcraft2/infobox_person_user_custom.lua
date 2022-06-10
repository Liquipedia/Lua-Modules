---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local User = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Variables = require('Module:Variables')
local RaceIcon = require('Module:RaceIcon').getBigIcon
local CleanRace = require('Module:CleanRace')

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

local _raceData

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomUser = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomUser.run(frame)
	local user = User(frame)
	user.args.informationType = user.args.informationType or 'User'
	_args = user.args

	user.shouldStoreData = CustomUser.shouldStoreData
	user.getStatusToStore = CustomUser.getStatusToStore
	user.getPersonType = CustomUser.getPersonType

	user.nameDisplay = CustomUser.nameDisplay
	user.createWidgetInjector = CustomUser.createWidgetInjector

	return user:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{name = 'Race', content = {_raceData.display}}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then return {}
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

function CustomInjector:addCustomCells()
	local widgets = {
		Cell{name = 'Languages', content = {_args.languages}},
		Cell{name = 'Favorite players', content = CustomUser:_getArgsfromBaseDefault('fav-player', 'fav-players')},
		Cell{name = 'Favorite casters', content = CustomUser:_getArgsfromBaseDefault('fav-caster', 'fav-casters')},
		Cell{name = 'Favorite teams', content = {_args['fav-teams']}}
	}
	if not String.isEmpty(_args['fav-team-1']) then
		table.insert(widgets, Title{name = 'Favorite teams'})
		table.insert(widgets, Center{content = {CustomUser:_getFavouriteTeams()}})
	end

	return widgets
end

function CustomUser:_getFavouriteTeams()
	local foundArgs = User:getAllArgsForBase(_args, 'fav-team-')

	local display = ''
	for _, item in ipairs(foundArgs) do
		local team = item:lower():gsub('_', ' ')
		display = display .. mw.ext.TeamTemplate.teamicon(team)
	end

	return display
end

function CustomUser:_getArgsfromBaseDefault(base, default)
	local foundArgs = User:getAllArgsForBase(_args, base)
	table.insert(foundArgs, _args[default])
	return foundArgs
end

function CustomUser:createWidgetInjector()
	return CustomInjector()
end

function CustomUser:nameDisplay()
	CustomUser._getRaceData(_args.race or 'unknown')
	local raceIcon = RaceIcon({'alt_' .. _raceData.race})
	local name = _args.id or self.pagename

	return raceIcon .. '&nbsp;' .. name
end

function CustomUser._getRaceData(race)
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

function CustomUser:shouldStoreData()
	Variables.varDefine('disable_SMW_storage', 'true')
	return false
end

function CustomUser:getStatusToStore() return '' end

function CustomUser:getCategories() return {} end

function CustomUser:getPersonType()
	return { store = 'User', category = 'User' }
end

return CustomUser
