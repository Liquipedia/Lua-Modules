---
-- @Liquipedia
-- wiki=worldofwarcraft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _ROLES = {
	-- Playes
	['healer'] = {category = 'Healers', variable = 'Healer', isplayer = true},
	['DPS'] = {category = 'DPS players', variable = 'DPS', isplayer = true},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', isplayer = false},
	['host'] = {category = 'Hosts', variable = 'Host', isplayer = false},
	['caster'] = {category = 'Casters', variable = 'Caster', isplayer = false},
}

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getWikiCategories = CustomPlayer.getWikiCategories

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._roleDisplay(_args.role),
				CustomPlayer._roleDisplay(_args.role2)
			}},
		}
	end
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer._getRoleData(role)
	return role and _ROLES[role:lower()] or nil
end

function CustomPlayer._roleDisplay(role)
	local roleData = CustomPlayer._getRoleData(role)
	if not roleData then
		return
	end
	return '[[:Category:' .. roleData.category .. '|' .. roleData.variable .. ']]'
end

function CustomPlayer:getWikiCategories(categories)
	local roleData = CustomPlayer._getRoleData(_args.role)
	local role2Data = CustomPlayer._getRoleData(_args.role2)

	if roleData then
		table.insert(categories, roleData.category)
	end

	if role2Data then
		table.insert(categories, role2Data.category)
	end

	return categories
end

return CustomPlayer
