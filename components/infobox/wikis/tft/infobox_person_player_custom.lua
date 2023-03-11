---
-- @Liquipedia
-- wiki=tft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Staff and Talents
	analyst = {category = 'Analysts', value = 'Analyst', type = 'talent'},
	observer = {category = 'Observers', value = 'Observer', type = 'talent'},
	host = {category = 'Hosts', value = 'Host', type = 'talent'},
	journalist = {category = 'Journalists', value = 'Journalist', type = 'talent'},
	expert = {category = 'Experts', value = 'Expert', type = 'talent'},
	coach = {category = 'Coaches', value = 'Coach', type = 'staff'},
	caster = {category = 'Casters', value = 'Caster', type = 'talent'},
	talent = {category = 'Talents', value = 'Talent', type = 'talent'},
	manager = {category = 'Managers', value = 'Manager', type = 'staff'},
	producer = {category = 'Producers', value = 'Producer', type = 'talent'},
}
ROLES['assistant coach'] = ROLES.coach

local DEFAULT_TYPE = 'player'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _pagename = mw.title.getCurrentTitle().prefixedText
local _args

function CustomPlayer.run(frame)
	local player = Player(frame)


	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.getPersonType = CustomPlayer.getPersonType

	_args = player.args

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

	return lpdbData
end

function CustomPlayer._getRoleData(key)
	local role = _args[key]
	if String.isEmpty(role) then
		return
	end

	return ROLES[role:lower()] or {}
end

function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('role', CustomPlayer._getRoleData('role').value)
	Variables.varDefine('role2', CustomPlayer._getRoleData('role2').value)
end

return CustomPlayer