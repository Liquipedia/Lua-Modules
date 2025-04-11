---
-- @Liquipedia
-- wiki=marvel rivals
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local CharacterIcon = Lua.import('Module:CharacterIcon')
local CharacterNames = Lua.import('Module:HeroNames')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	duelust = {category = 'Duelist Players', variable = 'Duelist', isplayer = true},
	flex = {category = 'Flex Players', variable = 'Flex', isplayer = true},
	strategist = {category = 'Strategist Players', variable = 'Strategist', isplayer = true},
	vanguard = {category = 'Vanguard Players', variable = 'Vanguard', isplayer = true},

	-- Staff and Talents
	analyst = {category = 'Analysts', variable = 'Analyst', isplayer = false},
	observer = {category = 'Observers', variable = 'Observer', isplayer = false},
	host = {category = 'Hosts', variable = 'Host', isplayer = false},
	coach = {category = 'Coaches', variable = 'Coach', isplayer = false},
	caster = {category = 'Casters', variable = 'Caster', isplayer = false},
	talent = {category = 'Talents', variable = 'Talent', isplayer = false},
	producer = {category = 'Producers', variable = 'Producer', isplayer = false},
	streamer = {category = 'Streamers', variable = 'Streamer', isplayer = false},
}

local SIZE_HERO = '25x25px'
local MAX_NUMBER_OF_SIGNATURE_HEROES = 3

---@class MarvelRivalsInfoboxPlayer: Person
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

	if id == 'custom' then
		local heroes = Array.sub(caller:getAllArgsForBase(args, 'hero'), 1, MAX_NUMBER_OF_SIGNATURE_HEROES)
		local heroIcons = Array.map(heroes, function(hero)
			return CharacterIcon.Icon{character = CharacterNames[hero:lower()], size = SIZE_HERO}
		end)

		Array.appendWith(widgets,
			Cell{
				name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
				content = {table.concat(heroIcons, '&nbsp;')},
			}
		)
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				caller:_displayRole(caller.role),
				caller:_displayRole(caller.role2),
			}},
		}

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

	-- store signature heroes with standardized name
	for heroIndex, hero in ipairs(self:getAllArgsForBase(args, 'hero')) do
		lpdbData.extradata['signatureHero' .. heroIndex] = CharacterNames[hero:lower()]
		if heroIndex == MAX_NUMBER_OF_SIGNATURE_HEROES then
			break
		end
	end

	lpdbData.type = self:_isPlayerOrStaff()

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(args.team2).page
	end

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

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(), self.args.team)
		local team2Page = String.isNotEmpty(self.args.team2) and Team.page(mw.getCurrentFrame(), self.args.team2) or nil
		return
			tostring(MatchTicker.player{recentLimit = 3}) ..
			Template.safeExpand(
				mw.getCurrentFrame(),
				'Upcoming and ongoing tournaments of',
				{team = teamPage}, {team2 = team2Page}
			)
	end
end

return CustomPlayer
