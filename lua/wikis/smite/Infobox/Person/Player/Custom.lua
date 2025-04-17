---
-- @Liquipedia
-- wiki=smite
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	['solo'] = {category = 'Solo players', display = 'Solo'},
	['jungler'] = {category = 'Jungle players', display = 'Jungler'},
	['support'] = {category = 'Support players', display = 'Support'},
	['mid'] = {category = 'Mid Lane players', display = 'Mid'},
	['carry'] = {category = 'Carry players', display = 'Carry'},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', display = 'Analyst'},
	['observer'] = {category = 'Observers', display = 'Observer'},
	['host'] = {category = 'Hosts', display = 'Host'},
	['coach'] = {category = 'Coaches', display = 'Coach'},
	['caster'] = {category = 'Casters', display = 'Caster'},
}

---@class SmiteInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)

	player:setWidgetInjector(CustomInjector(player))

	player.role = player:_getRoleData(player.args.role)
	player.role2 = player:_getRoleData(player.args.role2)

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	local caller = self.caller

	if id == 'role' then
		return {
			Cell{name = 'Role', content = {
				caller:_displayRole(caller.role),
				caller:_displayRole(caller.role2),
			}},
		}
	end
	return widgets
end

---@param role string?
---@return {category: string, display: string, isplayer: boolean?}?
function CustomPlayer:_getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param roleData {category: string, display: string, isplayer: boolean?}?
---@return string?
function CustomPlayer:_displayRole(roleData)
	if not roleData then return end

	return Page.makeInternalLink(roleData.display, ':Category:' .. roleData.category)
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category
	)
end

return CustomPlayer
