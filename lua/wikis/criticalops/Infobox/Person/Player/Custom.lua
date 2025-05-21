---
-- @Liquipedia
-- wiki=criticalops
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Staff and Talents
	['analyst'] = {category = 'Analysts', name = 'Analyst', staff = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', name = 'Broadcast Analyst', talent = true},
	['caster'] = {category = 'Casters', name = 'Caster', staff = true},
}

---@class COPSInfoboxPlayer: Person
---@field role {category: string, name: string, staff: boolean?, talent: boolean?}?
---@field role2 {category: string, name: string, staff: boolean?, talent: boolean?}?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.role = player:_getRoleData(player.args.role)
	player.role2 = player:_getRoleData(player.args.role2)

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller

	if id == 'role' then
		return {
			Cell{name = 'Role', content = {(caller.role or {}).name, (caller.role2 or {}).name}},
		}
	end
	return widgets
end

---@param role string?
---@return {category: string, variable: string, isplayer: boolean?}?
function CustomPlayer:_getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category
	)
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local roleData = self.role or {}
	if roleData.staff then
		return {store = 'staff', category = 'Staff'}
	elseif roleData.talent then
		return {store = 'talent', category = 'Talent'}
	end
	return {store = 'player', category = 'Player'}
end

return CustomPlayer
