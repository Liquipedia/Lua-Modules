---
-- @Liquipedia
-- wiki=omegastrikers
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	['forward'] = {category = 'Forwards', display = 'Forward'},
	['goalie'] = {category = 'Goalies', display = 'Goalie'},
	['goalkeeper'] = {category = 'Goalkeepers', display = 'Goalkeeper'},
	['flex'] = {category = 'Flex', display = 'Flex'},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', display = 'Analyst'},
	['observer'] = {category = 'Observers', display = 'Observer'},
	['host'] = {category = 'Hosts', display = 'Host'},
	['coach'] = {category = 'Coaches', display = 'Coach'},
	['caster'] = {category = 'Casters', display = 'Caster'},
}

---@class OmegaStrikersInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)

	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true
	player.args.history = TeamHistoryAuto._results{
		convertrole = true,
		player = player.pagename
	}
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
