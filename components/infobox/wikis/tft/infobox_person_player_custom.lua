---
-- @Liquipedia
-- wiki=tft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Staff and Talents
	analyst = {category = 'Analyst', value = 'Analyst', type = 'talent'},
	observer = {category = 'Observer', value = 'Observer', type = 'talent'},
	host = {category = 'Host', value = 'Host', type = 'talent'},
	journalist = {category = 'Journalist', value = 'Journalist', type = 'talent'},
	expert = {category = 'Expert', value = 'Expert', type = 'talent'},
	coach = {category = 'Coach', value = 'Coach', type = 'staff'},
	caster = {category = 'Caster', value = 'Caster', type = 'talent'},
	talent = {category = 'Talent', value = 'Talent', type = 'talent'},
	manager = {category = 'Manager', value = 'Manager', type = 'staff'},
	producer = {category = 'Producer', value = 'Producer', type = 'talent'},
	organizer = {category = 'Tournament Organizer', value = 'Tournament Organizer', type = 'staff'},
	creator = {category = 'Content Creator', value = 'Content Creator', type = 'talent'},
}
ROLES['assistant coach'] = ROLES.coach

local DEFAULT_TYPE = 'player'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.getPersonType = CustomPlayer.getPersonType

	_args = player.args
	_args.autoTeam = true

	return player:createInfobox()
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._getRoleData('role').value,
				CustomPlayer._getRoleData('role2').value,
				CustomPlayer._getRoleData('role3').value,
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			content = {_args.retired}
		})
	end
	return widgets
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')
	lpdbData.extradata.role3 = Variables.varDefault('role3')

	return lpdbData
end

function CustomPlayer._getRoleData(key)
	local role = _args[key]
	if String.isEmpty(role) then
		return {}
	end

	return ROLES[role:lower()] or {}
end

function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('role', CustomPlayer._getRoleData('role').value)
	Variables.varDefine('role2', CustomPlayer._getRoleData('role2').value)
	Variables.varDefine('role3', CustomPlayer._getRoleData('role3').value)
end

function CustomPlayer:getPersonType(args)
	local roleData = CustomPlayer._getRoleData('role')


	return {
		store = roleData.type or DEFAULT_TYPE,
		category = roleData.category or mw.getContentLanguage():ucfirst(DEFAULT_TYPE)
	}
end

return CustomPlayer
