---
-- @Liquipedia
-- wiki=smite
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Page = require('Module:Page')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	['solo'] = {category = 'Solo players', variable = 'Solo', isplayer = true},
	['jungler'] = {category = 'Jungle players', variable = 'Jungler', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['mid'] = {category = 'Mid Lane players', variable = 'Mid', isplayer = true},
	['carry'] = {category = 'Carry players', variable = 'Carry', isplayer = true},

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
	['streamer'] = {category = 'Streamers', variable = 'Streamer', isplayer = false},
}
ROLES['assistant coach'] = ROLES.coach
ROLES['head coach'] = ROLES.coach
ROLES['jgl'] = ROLES.jungler
ROLES['adc'] = ROLES.carry
ROLES['sup'] = ROLES.support
ROLES['top'] = ROLES.solo

---@class SmiteInfoboxPlayer: Person
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
		iconModule = 'Module:PositionIcon/data',
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
---@return {category: string, variable: string, isplayer: boolean?}?
function CustomPlayer:_getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param roleData {category: string, variable: string, isplayer: boolean?}?
---@return string?
function CustomPlayer:_displayRole(roleData)
	if not roleData then return end

	return Page.makeInternalLink(roleData.variable, ':Category:' .. roleData.category)
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category
	)
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.role = (self.role or {}).variable
	lpdbData.extradata.role2 = (self.role2 or {}).variable
	lpdbData.type = self:_isPlayerOrStaff()
	return lpdbData
end

---@return string
function CustomPlayer:_isPlayerOrStaff()
	local roleData
	if String.isNotEmpty(self.args.role) then
		roleData = ROLES[self.args.role:lower()]
	end
	-- If the role is missing, assume it is a player
	if roleData and roleData.isplayer == false then
		return 'staff'
	else
		return 'player'
	end
end

return CustomPlayer
