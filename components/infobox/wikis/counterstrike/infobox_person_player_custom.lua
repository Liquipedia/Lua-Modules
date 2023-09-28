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
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Game = Lua.import('Module:Game', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _BANNED = mw.loadData('Module:Banned')
local _ROLES = {
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
_ROLES.awp = _ROLES.awper
_ROLES.lurk = _ROLES.lurker
_ROLES.entryfragger = _ROLES.entry
_ROLES.rifle = _ROLES.rifler

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.args.history = player.args.team_history

	for steamKey, steamInput, steamIndex in Table.iter.pairsByPrefix(player.args, 'steam', {requireIndex = false}) do
		player.args['steamalternative' .. steamIndex] = steamInput
		player.args[steamKey] = nil
	end

	player.args.informationType = player.args.informationType or 'Player'

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getPersonType = CustomPlayer.getPersonType
	player.getWikiCategories = CustomPlayer.getWikiCategories

	player.args.gamesList = Array.filter(Game.listGames({ordered = true}), function (gameIdentifier)
			return player.args[gameIdentifier]
		end)

	_args = player.args

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents()},
			Cell{name = 'Years Active (Player)', content = {_args.years_active}},
			Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {_args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}},
		}
	elseif id == 'role' then
		local role = CustomPlayer._createRole('role', _args.role)
		local role2 = CustomPlayer._createRole('role2', _args.role2)

		return {
			Cell{name = (role2 and 'Roles' or 'Role'), content = {role, role2}},
		}
	elseif id == 'region' then
		return {}
	end

	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell {
			name = 'Games',
			content = Array.map(_args.gamesList, function (gameIdentifier)
					return Game.text{game = gameIdentifier}
				end)
		}
	}
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	local normalizeRole = function (role)
		local roleData = _ROLES[(role or ''):lower()]
		if roleData then
			return (roleData.store or roleData.display2 or roleData.display or ''):lower()
		end
	end

	lpdbData.extradata.role = normalizeRole(_args.role)
	lpdbData.extradata.role2 = normalizeRole(_args.role2)

	return lpdbData
end

function CustomPlayer._getStatusContents()
	local statusContents = {}

	if String.isNotEmpty(_args.status) then
		table.insert(statusContents, Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status)
	end

	if String.isNotEmpty(_args.banned) then
		local banned = _BANNED[string.lower(_args.banned)]
		if not banned then
			banned = '[[Banned Players|Multiple Bans]]'
			table.insert(statusContents, banned)
		end

		Array.extendWith(statusContents, Array.map(Player:getAllArgsForBase(_args, 'banned'),
				function(item)
					return _BANNED[string.lower(item)]
				end
			))
	end

	return statusContents
end

function CustomPlayer:getWikiCategories(categories)
	local typeCategory = self:getPersonType(_args).category

	Array.forEach(_args.gamesList, function (gameIdentifier)
			local prefix = Game.abbreviation{game = gameIdentifier} or Game.name{game = gameIdentifier}
			table.insert(categories, prefix .. ' ' .. typeCategory .. 's')
		end)

	if Table.isEmpty(_args.gamesList) then
		table.insert(categories, 'Gameless Players')
	end

	return categories
end

function CustomPlayer._createRole(key, role)
	if String.isEmpty(role) then
		return nil
	end

	local roleData = _ROLES[role:lower()]
	if not roleData then
		return nil
	end

	local category1 = 'Category:' .. roleData.category
	local category2 = roleData.category2 and 'Category:' .. roleData.category2 or nil

	Variables.varDefineEcho(key, roleData.variable)
	local text = '[[:' .. category1 .. '|' .. roleData.display .. ']]'

	if category2 then
		text = text .. ' ([[:' .. category2 .. '|' .. roleData.display2 .. ']])'
	end

	if Namespace.isMain() then
		text = text .. '[[Category:' .. roleData.category ..']]'
		if category2 then
			text = text .. '[[Category:' .. roleData.category2 ..']]'
		end
	end

	return text
end

function CustomPlayer._isNotPlayer(role)
	local roleData = _ROLES[(role or ''):lower()]
	return roleData and (roleData.talent or roleData.management or roleData.coach)
end

function CustomPlayer:getPersonType(args)
	local roleData = _ROLES[(args.role or ''):lower()]
	if roleData then
		if roleData.coach then
			return { store = 'Coach', category = 'Coache' }
		elseif roleData.management then
			return { store = 'Staff', category = 'Manager' }
		elseif roleData.talent then
			return { store = 'Talent', category = 'Talent' }
		end
	end
	return { store = 'Player', category = 'Player' }
end

return CustomPlayer
