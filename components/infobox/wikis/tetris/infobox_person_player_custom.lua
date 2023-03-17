---
-- @Liquipedia
-- wiki=tetris
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Role = require('Module:Role')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _role
local _role2

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	_role = Role.run({role = _args.role})
	_role2 = Role.run({role = _args.role2})

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getPersonType = CustomPlayer.getPersonType

	return player:createInfobox(frame)
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._createRole('role', _role),
				CustomPlayer._createRole('role2', _role2)
			}},
		}
	end
	return widgets
end

function CustomPlayer:adjustLPDB(lpdbData)

	lpdbData.extradata.role = _role.variable
	lpdbData.extradata.role2 = _role2.variable
	return lpdbData
end

function CustomPlayer._createRole(key, role)
	local roleData = role
	if not roleData then
		return nil
	end
	if Player:shouldStoreData(_args) then
		return roleData.category
	else
		return roleData.variable
	end
end

function CustomPlayer:getPersonType(args)
	local roleData = _role
	if roleData then
		if roleData.staff then
			return {store = 'Staff', category = 'Staff'}
		elseif roleData.talent then
			return {store = 'Talent', category = 'Talent'}
		end
	end
	return {store = 'Player', category = 'Player'}
end

return CustomPlayer
