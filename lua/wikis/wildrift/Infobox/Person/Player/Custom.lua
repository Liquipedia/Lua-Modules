---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local ChampionNames = mw.loadData('Module:ChampionNames')
local CharacterIcon = require('Module:CharacterIcon')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local TeamTemplate = require('Module:TeamTemplate')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	['baron'] = {category = 'Baron Lane players', variable = 'Baron', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['jungle'] = {category = 'Jungle players', variable = 'Jungle', isplayer = true},
	['mid'] = {category = 'Mid Lane players', variable = 'Mid', isplayer = true},
	['dragon'] = {category = 'Dragon Lane players', variable = 'Dragon', isplayer = true},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', isplayer = false},
	['observer'] = {category = 'Observers', variable = 'Observer', isplayer = false},
	['host'] = {category = 'Hosts', variable = 'Host', isplayer = false},
	['journalist'] = {category = 'Journalists', variable = 'Journalist', isplayer = false},
	['expert'] = {category = 'Experts', variable = 'Expert', isplayer = false},
	['coach'] = {category = 'Coaches', variable = 'Coach', isplayer = false},
	['caster'] = {category = 'Casters', variable = 'Caster', isplayer = false},
	['content creator'] = {category = 'Content Creators', variable = 'Content Creator', isplayer = false},
	['talent'] = {category = 'Talents', variable = 'Talent', isplayer = false},
	['manager'] = {category = 'Managers', variable = 'Manager', isplayer = false},
	['producer'] = {category = 'Producers', variable = 'Producer', isplayer = false},
	['admin'] = {category = 'Admins', variable = 'Admin', isplayer = false},
}
ROLES['assistant coach'] = ROLES.coach
ROLES['strategic coach'] = ROLES.coach
ROLES['positional coach'] = ROLES.coach
ROLES['head coach'] = ROLES.coach
ROLES['jgl'] = ROLES.jungle
ROLES['solomiddle'] = ROLES.mid
ROLES['carry'] = ROLES.dragon
ROLES['adc'] = ROLES.dragon
ROLES['bot'] = ROLES.dragon
ROLES['ad carry'] = ROLES.dragon
ROLES['sup'] = ROLES.support

local SIZE_CHAMPION = '25x25px'

---@class WildriftInfoboxPlayer: Person
---@field role {category: string, variable: string, isplayer: boolean?}?
---@field role2 {category: string, variable: string, isplayer: boolean?}?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	if String.isEmpty(player.args.history) then
		player.args.history = TeamHistoryAuto.results{addlpdbdata = true}
	end
	player.args.autoTeam = true
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

	if id == 'custom' then
		-- Signature Champion
		local championIcons = Array.map(caller:getAllArgsForBase(args, 'champion'), function(champion)
			return CharacterIcon.Icon{character = ChampionNames[champion:lower()], size = SIZE_CHAMPION}
		end)
		return {Cell{
			name = #championIcons > 1 and 'Signature Champions' or 'Signature Champions',
			content = {table.concat(championIcons, '&nbsp;')},
		}}
	elseif id == 'status' then
		local status = args.status and mw.getContentLanguage():ucfirst(args.status) or nil

		return {
			Cell{name = 'Status', content = {Page.makeInternalLink({onlyIfExists = true}, status) or status}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				caller:_displayRole(caller.role),
				caller:_displayRole(caller.role2),
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
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
	for index, champion in ipairs(self:getAllArgsForBase(args, 'champion')) do
		lpdbData.extradata['signatureChampion' .. index] = ChampionNames[champion:lower()]
	end
	lpdbData.type = self:_isPlayerOrStaff()

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = TeamTemplate.getPageName(args.team2)
	end

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = TeamTemplate.getPageName(self.args.team)
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}) ..
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
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
