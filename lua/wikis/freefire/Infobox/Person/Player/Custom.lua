---
-- @Liquipedia
-- wiki=freefire
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:lua')
local String = require('Module:StringUtils')
local Page = require('Module:Page')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	support = {category = 'Support players', variable = 'Support'},
	rusher = {category = 'Rusher', variable = 'Rusher'},
	sniper = {category = 'Snipers', variable = 'Snipers'},
	granader = {category = 'Granader', variable = 'Granader'},
	igl = {category = 'In-game leaders', variable = 'In-game leader'},
	captain = {category = 'Captain', variable = 'Captain'},

	--Staff and Talents
	analyst = {category = 'Analysts', variable = 'Analyst', staff = true},
	coach = {category = 'Coaches', variable = 'Coach', staff = true},
	['assistant coach'] = {category = 'Assistant Coach ', variable = 'Assistant Coach', staff = true},
	manager = {category = 'Managers', variable = 'Manager', staff = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', variable = 'Broadcast Analyst', talent = true},
	host = {category = 'Hosts', variable = 'Host', talent = true},
	journalist = {category = 'Journalists', variable = 'Journalist', talent = true},
	caster = {category = 'Casters', variable = 'Caster', talent = true},
	commentator = {category = 'Commentators', variable = 'Commentator', talent = true},
	producer = {category = 'Producers', variable = 'Producer', talent = true},
	streamer = {category = 'Streamers', variable = 'Streamer', talent = true},
	interviewer = {category = 'Interviewers', variable = 'Interviewer', talent = true},
}

---@class FreefireInfoboxPlayer: Person
---@field role {category: string, variable: string, talent: boolean?, staff: boolean?}?
---@field role2 {category: string, variable: string, talent: boolean?, staff: boolean?}?
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

	if id == 'role' then
		return {
			Cell{name = 'Role', content = {
				caller:_displayRole(caller.role),
				caller:_displayRole(caller.role2)
			}},
		}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents(args)},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.isplayer = tostring(CustomPlayer._isNotPlayer(args.role) or CustomPlayer._isNotPlayer(args.role2))
	lpdbData.extradata.role = (self.role or {}).variable
	lpdbData.extradata.role2 = (self.role2 or {}).variable

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	local team2 = args.team2link or args.team2
	if String.isNotEmpty(team2) then
		lpdbData.extradata.team2 = (mw.ext.TeamTemplate.raw(team2) or {}).page or team2
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

---@param role string?
---@return boolean
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
			return {store = 'Staff', category = 'Staff'}
		elseif roleData.talent then
			return {store = 'Talent', category = 'Talent'}
		end
	end
	return {store = 'Player', category = 'Player'}
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

	if not self:shouldStoreData(self.args) then
		return roleData.variable
	end

	return Page.makeInternalLink(roleData.variable, ':Category:' .. roleData.category)
end

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('role', (self.role or {}).variable)
	Variables.varDefine('role2', (self.role2 or {}).variable)
end

return CustomPlayer
