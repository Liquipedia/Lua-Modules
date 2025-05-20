---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local HeroNames = mw.loadData('Module:HeroNames')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local TeamTemplate = require('Module:TeamTemplate')
local Variables = require('Module:Variables')
local YearsActive = require('Module:YearsActive')

local Flags = Lua.import('Module:Flags')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local UpcomingTournaments = Lua.import('Module:Widget/Infobox/UpcomingTournaments')

local BANNED = mw.loadData('Module:Banned')
local ROLES = {
	-- Players
	['carry'] = {category = 'Carry players', variable = 'Carry', isplayer = true},
	['mid'] = {category = 'Solo middle players', variable = 'Solo Middle', isplayer = true},
	['solo middle'] = {category = 'Solo middle players', variable = 'Solo Middle', isplayer = true},
	['solomiddle'] = {category = 'Solo middle players', variable = 'Solo Middle', isplayer = true},
	['offlane'] = {category = 'Offlaners', variable = 'Offlaner', isplayer = true},
	['offlaner'] = {category = 'Offlaners', variable = 'Offlaner', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['captain'] = {category = 'Captains', variable = 'Captain', isplayer = true},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', isplayer = false},
	['observer'] = {category = 'Observers', variable = 'Observer', isplayer = false},
	['host'] = {category = 'Hosts', variable = 'Host', isplayer = false},
	['journalist'] = {category = 'Journalists', variable = 'Journalist', isplayer = false},
	['expert'] = {category = 'Experts', variable = 'Expert', isplayer = false},
	['coach'] = {category = 'Coaches', variable = 'Coach', isplayer = false},
	['caster'] = {category = 'Casters', variable = 'Caster', isplayer = false},
	['manager'] = {category = 'Managers', variable = 'Manager', isplayer = false},
	['streamer'] = {category = 'Streamers', variable = 'Streamer', isplayer = false},
}

local ROLES_CATEGORY = {
	host = 'Casters',
	caster = 'Casters'
}
local SIZE_HERO = '44x25px'
local CONVERSION_PLAYER_ID_TO_STEAM = 61197960265728

---@class Dota2InfoboxPlayer: Person
---@field role {category: string, variable: string, isplayer: boolean?}?
---@field role2 {category: string, variable: string, isplayer: boolean?}?
---@field basePageName string
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	-- Override links to allow one param to set multiple links
	player.args.datdota = player.args.playerid
	player.args.dotabuff = player.args.playerid
	player.args.stratz = player.args.playerid
	if Logic.isNumeric(player.args.playerid) then
		player.args.steamalternative = '765' .. (tonumber(player.args.playerid) + CONVERSION_PLAYER_ID_TO_STEAM)
	end

	player.args.informationType = player.args.informationType or 'Player'

	player.args.banned = tostring(player.args.banned or '')

	player.role = player:_getRoleData(player.args.role)
	player.role2 = player:_getRoleData(player.args.role2)
	player.basePageName = mw.title.getCurrentTitle().baseText

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local icons = Array.map(caller:getAllArgsForBase(args, 'hero'), function(hero)
			return CharacterIcon.Icon{character = HeroNames[hero:lower()], size = SIZE_HERO}
		end)
		return {
			Cell{name = 'Signature Hero', content = {table.concat(icons, '&nbsp;')}}
		}
	elseif id == 'status' then
		local statusContents = caller:_getStatusContents()

		local yearsActive = args.years_active
		if String.isEmpty(yearsActive) then
			yearsActive = YearsActive.display({player = caller.basePageName})
		else
			yearsActive = Page.makeInternalLink({onlyIfExists = true}, yearsActive)
		end

		local yearsActiveOrg = args.years_active_manage
		if not String.isEmpty(yearsActiveOrg) then
			yearsActiveOrg = Page.makeInternalLink({onlyIfExists = true}, yearsActiveOrg)
		end

		return {
			Cell{name = 'Status', content = statusContents},
			Cell{name = 'Years Active (Player)', content = {yearsActive}},
			Cell{name = 'Years Active (Org)', content = {yearsActiveOrg}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
		}
	elseif id == 'history' then
		if not String.isEmpty(args.history_iwo) then
			table.insert(widgets, Title{children = '[[Intel World Open|Intel World Open]] History'})
			table.insert(widgets, Center{children = {args.history_iwo}})
		end
		if not String.isEmpty(args.history_gfinity) then
			table.insert(widgets, Title{children = '[[Gfinity/Elite_Series|Gfinity Elite Series]] History'})
			table.insert(widgets, Center{children = {args.history_gfinity}})
		end
		if not String.isEmpty(args.history_odl) then
			table.insert(widgets, Title{children = '[[Oceania Draft League|Oceania Draft League]] History'})
			table.insert(widgets, Center{children = {args.history_odl}})
		end
	elseif id == 'role' then
		return {
			Cell{name = 'Current Role', content = {
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

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.status = lpdbData.status or 'Unknown'

	for heroIndex, hero in ipairs(self:getAllArgsForBase(args, 'hero')) do
		lpdbData.extradata['hero' .. heroIndex] = HeroNames[hero:lower()]
	end

	lpdbData.extradata.role = (self.role or {}).variable
	lpdbData.extradata.role2 = (self.role2 or {}).variable
	lpdbData.extradata['lc_id'] = self.basePageName:lower()
	lpdbData.extradata.team2 = mw.ext.TeamLiquidIntegration.resolve_redirect(
		not String.isEmpty(args.team2link) and args.team2link or args.team2 or '')
	lpdbData.extradata.playerid = args.playerid

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if Namespace.isMain() and String.isNotEmpty(self.args.team) then
		local teamData = TeamTemplate.getRawOrNil(self.args.team) or {}
		return HtmlWidgets.Fragment{
			children = {
				MatchTicker.participant{team = teamData.name},
				UpcomingTournaments{name = teamData.name}
			}
		}
	end
end

---@return string[]
function CustomPlayer:_getStatusContents()
	local args = self.args
	local statusContents = {}
	local status
	if not String.isEmpty(args.status) then
		status = Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status
	end
	table.insert(statusContents, status)

	local banned = BANNED[string.lower(args.banned or '')]
	if not banned and not String.isEmpty(args.banned) then
		banned = '[[Banned Players|Multiple Bans]]'
		table.insert(statusContents, banned)
	end

	statusContents = Array.map(self:getAllArgsForBase(args, 'banned'),
		function(item, _)
			return BANNED[string.lower(item)]
		end
	)

	return statusContents
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local countryRoleCategory = ROLES_CATEGORY[self.args.role] or 'Players'
	local countryRoleCategory2 = ROLES_CATEGORY[self.args.role2]

	Array.forEach(self.locations, function (country)
		local demonym = Flags.getLocalisation(country)
		Array.appendWith(categories,
			demonym .. ' ' .. countryRoleCategory,
			countryRoleCategory2 and (demonym .. ' ' .. countryRoleCategory2) or nil
		)
	end)

	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category
	)
end

---@return string[]
function CustomPlayer:getLocations()
	return Array.map(self:getAllArgsForBase(self.args, 'country'), function(country)
		return Flags.CountryName{flag = country}
	end)
end

return CustomPlayer
