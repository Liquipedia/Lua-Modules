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
local Template = require('Module:Template')
local YearsActive = require('Module:YearsActive')

local Flags = Lua.import('Module:Flags')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local BANNED = mw.loadData('Module:Banned')

local Roles = Lua.import('Module:Roles')
local ROLES = Roles.All
local InGameRoles = Roles.InGameRoles
local ContractRoles = Roles.ContractRoles

local ROLES_CATEGORY = {
	host = 'Casters',
	caster = 'Casters'
}
local SIZE_HERO = '44x25px'
local CONVERSION_PLAYER_ID_TO_STEAM = 61197960265728

---@class Dota2PersonRoleData
---@field category string
---@field category2 string?
---@field display string
---@field display2 string?
---@field store string?
---@field coach boolean?
---@field talent boolean?
---@field management boolean?

---@class Dota2InfoboxPlayer: Person
---@field role Dota2PersonRoleData?
---@field role2 Dota2PersonRoleData?
---@field roles Dota2PersonRoleData? 
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

	player.role = ROLES[(player.args.role or ''):lower()]
	player.role2 = ROLES[(player.args.role2 or ''):lower()]
	player.roles = {}
	if player.args.roles then
		local roleKeys = Array.parseCommaSeparatedString(player.args.roles)
		for _, roleKey in ipairs(roleKeys) do
			local key = roleKey:lower()
			local roleData = ROLES[key]
			if roleData then
				table.insert(player.roles, roleData)
			end
		end
	end

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
		local role = CustomPlayer._displayRole(caller.role)
		local role2 = CustomPlayer._displayRole(caller.role2)

		local inGameRoles = {}
		local contracts = {}
		local positions = {}

		if caller.roles and #caller.roles > 0 then
			for _, roleData in ipairs(caller.roles) do
				local roleDisplay = CustomPlayer._displayRole(roleData)

				if roleDisplay then
					local roleKey
					for key, data in pairs(ROLES) do
						if data == roleData then
							roleKey = key
							break
						end
					end

					if roleKey and InGameRoles[roleKey] then
						table.insert(inGameRoles, roleDisplay)
					elseif roleKey and ContractRoles[roleKey] then
						table.insert(contracts, roleDisplay)
					else
						table.insert(positions, roleDisplay)
					end
				end
			end
		end

		local inGameRolesDisplay = #inGameRoles > 0 and table.concat(inGameRoles, ", ") or nil
		local positionsDisplay = #positions > 0 and table.concat(positions, ", ") or nil
		local contractsDisplay = #contracts > 0 and table.concat(contracts, ", ") or nil

		local inGameRolesTitle = #inGameRoles > 1 and "In-game Roles" or "In-game Role"
		local positionsTitle = #positions > 1 and "Positions" or "Position"
		local contractsTitle = #contracts > 1 and "Contracts" or "Contract"

		local cells = {}

		if inGameRolesDisplay then
			table.insert(cells, Cell{name = inGameRolesTitle, content = {inGameRolesDisplay}})
		else
			table.insert(cells, Cell{name = (role2 and 'Roles' or 'Role'), content = {role, role2}})
		end

		if positionsDisplay then
			table.insert(cells, Cell{name = positionsTitle, content = {positionsDisplay}})
		end

		if contractsDisplay then
			table.insert(cells, Cell{name = contractsTitle, content = {contractsDisplay}})
		end

		return cells
	end
	return widgets
end

---@param role string?
---@return {category: string, variable: string, isplayer: boolean?}?
function CustomPlayer:_getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param roleData Dota2PersonRoleData?
---@return string?
function CustomPlayer._displayRole(roleData)
	if not roleData then return end

	---@param postFix string|integer|nil
	---@return string?
	local toDisplay = function(postFix)
		postFix = postFix or ''
		if not roleData['category' .. postFix] then return end
		return Page.makeInternalLink(roleData['display' .. postFix], ':Category:' .. roleData['category' .. postFix])
	end

	local role1Display = toDisplay()
	local role2Display = toDisplay(2)
	if role1Display and role2Display then
		role2Display = '(' .. role2Display .. ')'
	end

	return table.concat({role1Display, role2Display}, ' ')
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

	lpdbData.extradata['lc_id'] = self.basePageName:lower()
	lpdbData.extradata.team2 = mw.ext.TeamLiquidIntegration.resolve_redirect(
		not String.isEmpty(args.team2link) and args.team2link or args.team2 or '')
	lpdbData.extradata.playerid = args.playerid

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if Namespace.isMain() then
		return tostring(Template.safeExpand(
			mw.getCurrentFrame(), 'Upcoming_and_ongoing_matches_of_player', {player = self.basePageName})
			.. '<br>' .. Template.safeExpand(
			mw.getCurrentFrame(), 'Upcoming_and_ongoing_tournaments_of_player', {player = self.basePageName})
		)
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
		return Flags.CountryName(country)
	end)
end

return CustomPlayer
