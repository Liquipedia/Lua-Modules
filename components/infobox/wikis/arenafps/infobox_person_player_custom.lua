---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	duel = {variable = 'Duel', isplayer = true},
	tdm = {variable = 'TDM', isplayer = true},
	ctf = {variable = 'CTF', isplayer = true},
	sacrifice = {variable = 'Sacrifice', isplayer = true},
	['3vs3'] = {variable = '3vs3', isplayer = true},

	-- Staff and Talents
	analyst = {variable = 'Analyst', isplayer = false},
	manager = {variable = 'Manager', isplayer = false},
	caster = {variable = 'Caster', isplayer = false},
}
ROLES.dueler = ROLES.duel

local CustomPlayer = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = Array.map(Player:getAllArgsForBase(_args, 'role'), function(role)
				return CustomPlayer._roleDisplay(role)
			end)},
		}
	elseif id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active (Player)', content = {_args.years_active}})
		table.insert(widgets, Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}})
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	local games = {}
	for param in pairs(_args) do
		if Game.isValid(param) then
			table.insert(games, Page.makeInternalLink({}, Game.name{game = param}, Game.link{game = param}))
		end
	end
	table.insert(widgets, Cell{name = 'Games', content = games})
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer._getRoleData(role)
	return role and ROLES[role:lower()] or nil
end

function CustomPlayer._roleDisplay(role)
	local roleData = CustomPlayer._getRoleData(role)
	return roleData and roleData.variable or nil
end

return CustomPlayer
