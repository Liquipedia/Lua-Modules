---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:MatchTicker/Custom')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	['top'] = {category = 'Top Lane players', variable = 'Top', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['jungle'] = {category = 'Jungle players', variable = 'Jungle', isplayer = true},
	['mid'] = {category = 'Mid Lane players', variable = 'Mid', isplayer = true},
	['bottom'] = {category = 'Bot Lane players', variable = 'Bot', isplayer = true},

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
ROLES['strategic coach'] = ROLES.coach
ROLES['positional coach'] = ROLES.coach
ROLES['head coach'] = ROLES.coach
ROLES['jgl'] = ROLES.jungle
ROLES['solomiddle'] = ROLES.mid
ROLES['carry'] = ROLES.bottom
ROLES['adc'] = ROLES.bottom
ROLES['bot'] = ROLES.bottom
ROLES['ad carry'] = ROLES.bottom
ROLES['sup'] = ROLES.support

---@class LeagueoflegendsInfoboxPlayer: Person
---@field role {category: string, variable: string, isplayer: boolean?}?
---@field role2 {category: string, variable: string, isplayer: boolean?}?
---@field role3 {category: string, variable: string, isplayer: boolean?}?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.role = player:_getRoleData(player.args.role)
	player.role2 = player:_getRoleData(player.args.role2)
	player.role3 = player:_getRoleData(player.args.role3)

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'status' then
		local status = args.status
		if String.isNotEmpty(status) then
			status = mw.getContentLanguage():ucfirst(status)
		end

		return {
			Cell{name = 'Status', content = {Page.makeInternalLink({onlyIfExists = true},
						status) or status}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				caller:_displayRole(caller.role),
				caller:_displayRole(caller.role2),
				caller:_displayRole(caller.role3),
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			content = {args.retired}
		})
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
	lpdbData.extradata.role3 = (self.role3 or {}).variable

	lpdbData.extradata.signatureChampion1 = args.champion1 or args.champion
	lpdbData.extradata.signatureChampion2 = args.champion2
	lpdbData.extradata.signatureChampion3 = args.champion3
	lpdbData.extradata.signatureChampion4 = args.champion4
	lpdbData.extradata.signatureChampion5 = args.champion5
	lpdbData.type = self:_isPlayerOrStaff()

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(args.team2).page
	end

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(),self.args.team)
		return tostring(MatchTicker.participant({team = teamPage}))
			.. Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
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
