---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local CustomPerson = Lua.import('Module:Infobox/Person/Custom', {requireDevIfEnabled = true})

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomUser = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _user

function CustomUser.run(frame)
	local user = CustomPerson(frame)
	user.args.informationType = user.args.informationType or 'User'
	_user = user
	_args = user.args

	user.shouldStoreData = CustomUser.shouldStoreData
	user.getStatusToStore = CustomUser.getStatusToStore
	user.getPersonType = CustomUser.getPersonType
	user.createWidgetInjector = CustomUser.createWidgetInjector
	user._getArgsfromBaseDefault = CustomUser._getArgsfromBaseDefault
	user._getFavouriteTeams = CustomUser._getFavouriteTeams

	return user:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{name = 'Race', content = {_user:getRaceData(_args.race or 'unknown')}}
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
		Cell{name = 'Favorite players', content = _user:_getArgsfromBaseDefault('fav-player', 'fav-players')},
		Cell{name = 'Favorite casters', content = _user._getArgsfromBaseDefault('fav-caster', 'fav-casters')},
		Cell{name = 'Favorite teams', content = {_args['fav-teams']}}
	}
	if not String.isEmpty(_args['fav-team-1']) then
		table.insert(widgets, Title{name = 'Favorite teams'})
		table.insert(widgets, Center{content = {_user._getFavouriteTeams()}})
	end

	return widgets
end

function CustomUser:_getFavouriteTeams()
	local foundArgs = _user:getAllArgsForBase(_args, 'fav-team-')

	local display = ''
	for _, item in ipairs(foundArgs) do
		local team = item:lower():gsub('_', ' ')
		display = display .. mw.ext.TeamTemplate.teamicon(team)
	end

	return display
end

function CustomUser:_getArgsfromBaseDefault(base, default)
	local foundArgs = _user:getAllArgsForBase(_args, base)
	table.insert(foundArgs, _args[default])
	return foundArgs
end

function CustomUser:createWidgetInjector()
	return CustomInjector()
end

function CustomUser:shouldStoreData()
	Variables.varDefine('disable_LPDB_storage', 'true')
	return false
end

function CustomUser:getStatusToStore() return '' end

function CustomUser:getCategories() return {} end

function CustomUser:getPersonType()
	return {store = 'User', category = 'User'}
end

return CustomUser
