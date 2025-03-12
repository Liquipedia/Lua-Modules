---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Game = Lua.import('Module:Game')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local BANNED = mw.loadData('Module:Banned')
local ROLES = {
	-- Players
	['awper'] = {category = 'AWPers', display = 'AWPer', store = 'awp'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leader', store = 'igl'},
	['lurker'] = {category = 'Riflers', display = 'Rifler', category2 = 'Lurkers', display2 = 'lurker'},
	['support'] = {category = 'Riflers', display = 'Rifler', category2 = 'Support players', display2 = 'support'},
	['entry'] = {category = 'Riflers', display = 'Rifler', category2 = 'Entry fraggers', display2 = 'entry fragger'},
	['rifler'] = {category = 'Riflers', display = 'Rifler'},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', display = 'Analyst', coach = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', display = 'Broadcast Analyst', talent = true},
	['observer'] = {category = 'Observers', display = 'Observer', talent = true},
	['host'] = {category = 'Hosts', display = 'Host', talent = true},
	['journalist'] = {category = 'Journalists', display = 'Journalist', talent = true},
	['expert'] = {category = 'Experts', display = 'Expert', talent = true},
	['producer'] = {category = 'Production Staff', display = 'Producer', talent = true},
	['director'] = {category = 'Production Staff', display = 'Director', talent = true},
	['executive'] = {category = 'Organizational Staff', display = 'Executive', management = true},
	['coach'] = {category = 'Coaches', display = 'Coach', coach = true},
	['assistant coach'] = {category = 'Coaches', display = 'Assistant Coach', coach = true},
	['manager'] = {category = 'Managers', display = 'Manager', management = true},
	['director of esport'] = {category = 'Organizational Staff', display = 'Director of Esport', management = true},
	['caster'] = {category = 'Casters', display = 'Caster', talent = true},
}
ROLES.awp = ROLES.awper
ROLES.lurk = ROLES.lurker
ROLES.entryfragger = ROLES.entry
ROLES.rifle = ROLES.rifler

---@class CounterstrikePersonRoleData
---@field category string
---@field category2 string?
---@field display string
---@field display2 string?
---@field store string?
---@field coach boolean?
---@field talent boolean?
---@field management boolean?

---@class CounterstrikeInfoboxPlayer: Person
---@field gamesList string[]
---@field role CounterstrikePersonRoleData?
---@field role2 CounterstrikePersonRoleData?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = player.args.team_history

	for steamKey, steamInput, steamIndex in Table.iter.pairsByPrefix(player.args, 'steam', {requireIndex = false}) do
		player.args['steamalternative' .. steamIndex] = steamInput
		player.args[steamKey] = nil
	end

	player.args.informationType = player.args.informationType or 'Player'

	player.args.banned = tostring(player.args.banned or '')

	player.gamesList = Array.filter(Game.listGames({ordered = true}), function (gameIdentifier)
			return player.args[gameIdentifier]
		end)

	player.role = ROLES[(player.args.role or ''):lower()]
	player.role2 = ROLES[(player.args.role2 or ''):lower()]

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return {
			Cell {
				name = 'Games',
				content = Array.map(caller.gamesList, function (gameIdentifier)
						return Game.text{game = gameIdentifier}
					end)
			}
		}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = caller:_getStatusContents(args)},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
		}
	elseif id == 'role' then
		local role = CustomPlayer._displayRole(caller.role)
		local role2 = CustomPlayer._displayRole(caller.role2)

		return {
			Cell{name = (role2 and 'Roles' or 'Role'), content = {role, role2}},
		}
	elseif id == 'region' then
		return {}
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	local normalizeRole = function(roleData)
		if not roleData then return end
		return (roleData.store or roleData.display2 or roleData.display or ''):lower()
	end

	lpdbData.extradata.role = normalizeRole(self.role)
	lpdbData.extradata.role2 = normalizeRole(self.role2)

	return lpdbData
end

---@param args table
---@return table
function CustomPlayer:_getStatusContents(args)
	local statusContents = {}

	if String.isNotEmpty(args.status) then
		table.insert(statusContents, Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status)
	end

	if String.isNotEmpty(args.banned) then
		local banned = BANNED[string.lower(args.banned)]
		if not banned then
			table.insert(statusContents, '[[Banned Players|Multiple Bans]]')
		end

		Array.extendWith(statusContents, Array.map(self:getAllArgsForBase(args, 'banned'),
				function(item)
					return BANNED[string.lower(item)]
				end
			))
	end

	return statusContents
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local typeCategory = self:getPersonType(self.args).category

	Array.forEach(self.gamesList, function (gameIdentifier)
			local prefix = Game.abbreviation{game = gameIdentifier} or Game.name{game = gameIdentifier}
			table.insert(categories, prefix .. ' ' .. typeCategory .. 's')
		end)

	if Table.isEmpty(self.gamesList) then
		table.insert(categories, 'Gameless Players')
	end

	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category,
		(self.role or {}).category2,
		(self.role2 or {}).category2
	)
end

---@param roleData CounterstrikePersonRoleData?
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

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local roleData = self.role
	if roleData then
		if roleData.coach then
			return {store = 'Coach', category = 'Coache'}
		elseif roleData.management then
			return {store = 'Staff', category = 'Manager'}
		elseif roleData.talent then
			return {store = 'Talent', category = 'Talent'}
		end
	end
	return {store = 'Player', category = 'Player'}
end

return CustomPlayer
