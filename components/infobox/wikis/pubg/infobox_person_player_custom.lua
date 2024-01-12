---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local _ROLES = {
	-- Playes
	['sniper'] = {category = 'Snipers', variable = 'Sniper', isplayer = true},
	['attacker'] = {category = 'Attackers', variable = 'ATKs', isplayer = true},
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},
	['fragger'] = {category = 'Fraggers', variable = 'Fragger', isplayer = true},
	['scout'] = {category = 'Scouts', variable = 'Scout', isplayer = true},
	['support'] = {category = 'Supports', variable = 'Support', isplayer = true},
	['entry fragger'] = {category = 'Entry fraggers', variable = 'Entry Fragger', isplayer = true},
	['rifler'] = {category = 'Riflers', variable = 'Rifler', isplayer = true},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', isplayer = false},
	['observer'] = {category = 'Observers', variable = 'Observer', isplayer = false},
	['host'] = {category = 'Hosts', variable = 'Host', isplayer = false},
	['journalist'] = {category = 'Journalists', variable = 'Journalist', isplayer = false},
	['expert'] = {category = 'Experts', variable = 'Expert', isplayer = false},
	['coach'] = {category = 'Coaches', variable = 'Coach', isplayer = false},
	['caster'] = {category = 'Casters', variable = 'Caster', isplayer = false},
	['talent'] = {category = 'Talents', variable = 'Talent', isplayer = false},
	['manager'] = {category = 'Managers', variable = 'Manager', isplayer = false},
	['producer'] = {category = 'Producers', variable = 'Producer', isplayer = false},
	['admin'] = {category = 'Admins', variable = 'Admin', isplayer = false},
}

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	_args = player.args

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active (Player)', content = {_args.years_active}})
		table.insert(widgets, Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}})
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._createRoleDisplay('role', _args.role),
				CustomPlayer._createRoleDisplay('role2', _args.role2)
			}},
		}
	elseif id == 'history' and _args.nationalteams then
		table.insert(widgets, 1, Title{name = 'National Teams'})
		table.insert(widgets, 2, Center{content = {_args.nationalteams}})
	end
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')

	lpdbData.type = CustomPlayer._isPlayerOrStaff()

	if String.isNotEmpty(_args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(_args.team2).page
	end

	return lpdbData
end

function CustomPlayer._createRoleDisplay(key, role)
	if String.isEmpty(role) then
		return nil
	end

	local roleData = _ROLES[role:lower()]
	if not roleData then
		return nil
	end
	if Player:shouldStoreData(_args) then
		local categoryCoreText = 'Category:' .. roleData.category

		return '[[' .. categoryCoreText .. ']]' .. '[[:' .. categoryCoreText .. '|' ..
			Variables.varDefineEcho(key or 'role', roleData.variable) .. ']]'
	else
		return Variables.varDefineEcho(key or 'role', roleData.variable)
	end
end

function CustomPlayer:createBottomContent()
	if self:shouldStoreData(_args) and String.isNotEmpty(_args.team) then
		return Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = self.pagename})
	end
end

function CustomPlayer._isPlayerOrStaff()
	local roleData
	if String.isNotEmpty(_args.role) then
		roleData = _ROLES[_args.role:lower()]
	end
	-- If the role is missing, assume it is a player
	if roleData and roleData.isplayer == false then
		return 'staff'
	else
		return 'player'
	end
end

return CustomPlayer
