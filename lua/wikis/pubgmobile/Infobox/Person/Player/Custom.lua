---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
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

---@class PubgmobileInfoboxPlayer: Person
---@field role {category: string, variable: string, isplayer: boolean?}?
---@field role2 {category: string, variable: string, isplayer: boolean?}?
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
	local args = caller.args

	if id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents(args)},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
		}
	elseif id == 'region' then return {}
	elseif id == 'role' then
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

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('role', (self.role or {}).variable)
	Variables.varDefine('role2', (self.role2 or {}).variable)
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

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(args.team2).page
	end

	return lpdbData
end

---@param args table
---@return string[]
function CustomPlayer._getStatusContents(args)
	if String.isEmpty(args.status) then
		return {}
	end
	return {Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status}
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) then
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of player', {player = self.pagename})
	end
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
