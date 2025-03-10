---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local PlayerIntroduction = require('Module:PlayerIntroduction/Custom')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- staff
	coach = {category = 'Coache', variable = 'Coach', isplayer = false, personType = 'staff'},
	manager = {category = 'Manager', variable = 'Manager', isplayer = false, personType = 'staff'},

	-- talent
	analyst = {category = 'Analyst', variable = 'Analyst', isplayer = false, personType = 'talent'},
	caster = {category = 'Caster', variable = 'Caster', isplayer = false, personType = 'talent'},
	['content creator'] = {
		category = 'Content Creator', variable = 'Content Creator', isplayer = false, personType = 'talent'},
	host = {category = 'Host', variable = 'Host', isplayer = false, personType = 'talent'},
}
ROLES['assistant coach'] = ROLES.coach
ROLES.commentator = ROLES.caster

---@class BrawlstarsInfoboxPlayer: Person
---@field role {category?: string, variable: string?, isplayer: boolean?, personType: string?}
---@field role2 {category?: string, variable: string?, isplayer: boolean?, personType: string?}
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.role = CustomPlayer._getRoleData(player.args.role) or {}
	player.role2 = CustomPlayer._getRoleData(player.args.role2) or {}

	local args = player.args

	local builtInfobox = player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((args.autoPI or ''):lower()) then
		autoPlayerIntro = PlayerIntroduction.run{
			team = args.team,
			name = Logic.emptyOr(args.romanized_name, args.name),
			romanizedname = args.romanized_name,
			status = args.status,
			type = player.role.personType,
			role = player.role.variable,
			role2 = player.role2.variable,
			id = args.id,
			idIPA = args.idIPA,
			idAudio = args.idAudio,
			birthdate = player.age.birthDateIso,
			deathdate = player.age.deathDateIso,
			nationality = args.country,
			nationality2 = args.country2,
			nationality3 = args.country3,
			subtext = args.subtext,
			freetext = args.freetext,
		}
	elseif String.isNotEmpty(args.freetext) then
		autoPlayerIntro = args.freetext
	end

	return mw.html.create()
		:node(builtInfobox)
		:node(autoPlayerIntro)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		if String.isEmpty(args.mmr) then return {} end

		local mmrDisplay = '[[Leaderboards|' .. args.mmr .. ']]'
		if String.isNotEmpty(args.mmrdate) then
			mmrDisplay = mmrDisplay .. '&nbsp;<small><i>(last update: ' .. args.mmrdate .. '</i></small>'
		end

		return {Cell{name = 'Solo MMR', content = {mmrDisplay}}}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = {CustomPlayer._getStatus(args)}},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
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

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.role = self.role.variable
	lpdbData.extradata.role2 = self.role2.variable

	lpdbData.type = Logic.emptyOr(self.role.variable, 'player')

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	return lpdbData
end

function CustomPlayer:createBottomContent()
	local components = {}
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = TeamTemplate.getPageName(self.args.team)

		table.insert(components,
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}))
		table.insert(components,
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage}))
	end

	return table.concat(components)
end

---@param args table
---@return string?
function CustomPlayer._getStatus(args)
	if String.isNotEmpty(args.status) then
		return Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status
	end
end

function CustomPlayer:getPersonType(args)
	local roleData = CustomPlayer._getRoleData(args.role)
	if roleData then
		local personType = mw.getContentLanguage():ucfirst(roleData.personType or 'player')
		local categoryValue = roleData.category == ROLES.coach.category and roleData.category or personType

		return {store = personType, category = categoryValue}
	end

	return {store = 'Player', category = 'Player'}
end

---@param role string?
---@return {category: string, variable: string, isplayer: boolean?, personType: string}?
function CustomPlayer._getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param roleData {category: string, variable: string, isplayer: boolean?, personType: string}
---@return string?
function CustomPlayer:_displayRole(roleData)
	if Table.isEmpty(roleData) then return end

	return Page.makeInternalLink(roleData.variable, ':Category:' .. roleData.category)
end

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	if self.role then
		Variables.varDefine('role', self.role.variable)
		Variables.varDefine('type', self.role.personType)
	end

	-- If the role is missing, assume it is a player
	if self.role and self.role.isplayer == false then
		Variables.varDefine('isplayer', 'false')
	else
		Variables.varDefine('isplayer', 'true')
	end

	if self.role2 then
		Variables.varDefine('role2', self.role2.variable)
		Variables.varDefine('type2', self.role2.personType)
	end
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	if self.role2.category then
		table.insert(categories, self.role2.category .. 's')
	end
	return categories
end

return CustomPlayer
