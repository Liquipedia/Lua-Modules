---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Person/User/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local User = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')

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

	user.createWidgetInjector = CustomUser.createWidgetInjector

	return user:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if
		id == 'history' and
		not (String.isEmpty(_args.team_history) and String.isEmpty(_args.clan_history))
	then
		return {
			Title{ name = 'History' },
			Center{content = {_args.team_history}},
			Center{content = {_args.clan_history}},
		}
	end
	return widgets
end

function CustomInjector:addCustomCells()
	local widgets = {
		Cell{name = 'Gender', content = {_args.gender}},
		Cell{name = 'Languages', content = {_args.languages}},
		Cell{name = 'Favorite Players', content = CustomUser:_getArgsfromBaseDefault('fav-player', 'fav-players')},
		Cell{name = 'Favorite Casters', content = CustomUser:_getArgsfromBaseDefault('fav-caster', 'fav-casters')},
		Cell{name = 'Favorite Teams', content = {_args['fav-teams']}}
	}
	if not String.isEmpty(_args['fav-team-1']) then
		table.insert(widgets, Title{name = 'Favorite Teams'})
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

function CustomUser:shouldStoreData() return false end

function CustomUser:getStatusToStore() return '' end

function CustomUser:getCategories() return {} end

function CustomUser:getPersonType()
	return { store = 'User', category = 'User' }
end

return CustomUser
