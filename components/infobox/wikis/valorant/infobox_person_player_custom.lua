---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Region = require('Module:Region')
local SignaturePlayerAgents = require('Module:SignaturePlayerAgents')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader'},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', staff = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', variable = 'Broadcast Analyst', talent = true},
	['observer'] = {category = 'Observers', variable = 'Observer', talent = true},
	['host'] = {category = 'Host', variable = 'Host', talent = true},
	['journalist'] = {category = 'Journalists', variable = 'Journalist', talent = true},
	['expert'] = {category = 'Experts', variable = 'Expert', talent = true},
	['coach'] = {category = 'Coaches', variable = 'Coach', staff = true},
	['caster'] = {category = 'Casters', variable = 'Caster', talent = true},
	['manager'] = {category = 'Managers', variable = 'Manager', staff = true},
	['streamer'] = {category = 'Streamers', variable = 'Streamer', talent = true},
	['producer'] = {category = 'Production Staff', variable = 'Producer', talent = true},
	['director'] = {category = 'Production Staff', variable = 'Director', talent = true},
	['interviewer'] = {category = 'Interviewers', variable = 'Interviewer', talent = true},
}
ROLES['in-game leader'] = ROLES.igl

local SIZE_AGENT = '20px'

---@class ValorantInfoboxPlayer: Person
---@field role {category: string, variable: string, talent: boolean?, staff: boolean?}?
---@field role2 {category: string, variable: string, talent: boolean?, staff: boolean?}?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = TeamHistoryAuto._results{convertrole = 'true'}
	player.args.autoTeam = true
	player.args.agents = SignaturePlayerAgents.get{player = player.pagename, top = 3}
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
		local icons = Array.map(args.agents, function(agent)
			return CharacterIcon.Icon{character = agent, size = SIZE_AGENT}
		end)
		return {
			Cell{name = 'Signature Hero', content = {table.concat(icons, '&nbsp;')}}
		}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents(args)},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
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
	elseif id == 'region' then
		return {}
	end
	return widgets
end

---@param role string?
---@return {category: string, variable: string, talent: boolean?, staff: boolean?}?
function CustomPlayer:_getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param roleData {category: string, variable: string, talent: boolean?, staff: boolean?}?
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
	lpdbData.extradata.isplayer = CustomPlayer._isNotPlayer(args.role) and 'false' or 'true'

	Array.forEach(args.agents, function (agent, index)
		lpdbData.extradata['agent' .. index] = agent
	end)

	lpdbData.region = Region.name({region = args.region, country = args.country})

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

---@param role string?
---@return boolean?
function CustomPlayer._isNotPlayer(role)
	local roleData = ROLES[(role or ''):lower()]
	return roleData and (roleData.talent or roleData.staff)
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local roleData = ROLES[(args.role or ''):lower()]
	if roleData then
		if roleData.staff then
			return {store = 'staff', category = 'Staff'}
		elseif roleData.talent then
			return {store = 'talent', category = 'Talent'}
		end
	end
	return {store = 'player', category = 'Player'}
end

return CustomPlayer
