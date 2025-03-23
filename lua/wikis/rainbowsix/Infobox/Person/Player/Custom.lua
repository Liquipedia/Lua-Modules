---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local CharacterNames = require('Module:CharacterNames')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')

local ACHIEVEMENTS_BASE_CONDITIONS = {
	'[[liquipediatiertype::!Showmatch]]',
	'[[liquipediatiertype::!Qualifier]]',
	'([[liquipediatier::1]] OR [[liquipediatier::2]])',
	'[[placement::1]]',
}

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local BANNED = mw.loadData('Module:Banned')
local ROLES = {
	-- Players
	['entry'] = {category = 'Entry fraggers', variable = 'Entry fragger', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['flex'] = {category = 'Flex players', variable = 'Flex', isplayer = true},
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},

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
ROLES.entryfragger = ROLES.entry
ROLES['assistant coach'] = ROLES.coach

local GAMES = {
	r6s = '[[Rainbow Six Siege|Siege]]',
	vegas2 = '[[Rainbow Six Vegas 2|Vegas 2]]',
}
GAMES.siege = GAMES.r6s

local SIZE_OPERATOR = '25x25px'

---@class RainbowsixInfoboxPlayer: Person
---@field role {category: string, variable: string, isplayer: boolean?}?
---@field role2 {category: string, variable: string, isplayer: boolean?}?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = TeamHistoryAuto.results{addlpdbdata = true, specialRoles = true}
	-- Automatic achievements
	player.args.achievements = Achievements.player{
		baseConditions = ACHIEVEMENTS_BASE_CONDITIONS
	}

	player.args.banned = tostring(player.args.banned or '')

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
		-- Signature Operators
		local operatorIcons = Array.map(caller:getAllArgsForBase(args, 'operator'), function(operator)
			return CharacterIcon.Icon{character = CharacterNames[operator:lower()], size = SIZE_OPERATOR}
		end)
		table.insert(widgets, Cell{
			name = #operatorIcons > 1 and 'Signature Operators' or 'Signature Operator',
			content = {table.concat(operatorIcons, '&nbsp;')},
		})

		-- Active in Games
		local activeInGames = {}
		Table.iter.forEachPair(GAMES, function(key)
			if args[key] then
				table.insert(activeInGames, GAMES[key])
			end
		end)
		table.insert(widgets, Cell{
			name = #activeInGames > 1 and 'Games' or 'Game',
			content = activeInGames,
		})

	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = caller:_getStatusContents()},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
			Cell{name = 'Time Banned', content = {args.time_banned}},
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
	for _, operator, operatorIndex in Table.iter.pairsByPrefix(args, 'operator', {requireIndex = false}) do
		lpdbData.extradata['signatureOperator' .. operatorIndex] = CharacterNames[operator:lower()]
	end
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
		local teamPage = TeamTemplate.getPageName(self.args.team)
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}) ..
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
	end
end

---@return string[]
function CustomPlayer:_getStatusContents()
	local args = self.args
	local statusContents = {}

	if String.isNotEmpty(args.status) then
		table.insert(statusContents, Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status)
	end

	local banned = BANNED[string.lower(args.banned or '')]
	if not banned and String.isNotEmpty(args.banned) then
		banned = '[[Banned Players|Multiple Bans]]'
		table.insert(statusContents, banned)
	end

	return Array.extendWith(statusContents,
		Array.map(self:getAllArgsForBase(args, 'banned'),
			function(item, _)
				return BANNED[string.lower(item)]
			end
		)
	)
end

---@return string
function CustomPlayer:_isPlayerOrStaff()
	-- If the role is missing, assume it is a player
	if self.role and self.role.isplayer == false then
		return 'staff'
	else
		return 'player'
	end
end

return CustomPlayer
