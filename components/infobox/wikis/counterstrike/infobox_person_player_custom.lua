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

local GAMES = {
	cs = {name = 'Counter-Strike', link = 'Counter-Strike', category = 'CS', order = 1},
	cscz = {name = 'Condition Zero', link = 'Counter-Strike: Condition Zero', category = 'CSCZ', order = 2},
	css = {name = 'Source', link = 'Counter-Strike: Source', category = 'CSS', order = 3},
	cso = {name = 'Online', link = 'Counter-Strike Online', category = 'CSO', order = 4},
	csgo = {name = 'Global Offensive', link = 'Counter-Strike: Global Offensive', category = 'CSGO', order = 5},
}

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.args.history = player.args.team_history
	player.args.steamalternative = player.args.steam
	player.args.steam = nil

	player.args.informationType = player.args.informationType or 'Player'

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.getPersonType = CustomPlayer.getPersonType
	player.getWikiCategories = CustomPlayer.getWikiCategories

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
	end

	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell {
			name = 'Games',
			content = Array.map(CustomPlayer._getGames(), function (gameData)
				return Page.makeInternalLink({}, gameData.name, gameData.link)
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

function CustomPlayer._getGames()
	return Array.sortBy(Array.extractValues(Table.map(GAMES, function (key, data)
		if _args[key] then
			return key, data
		end
		return key, nil
	end)), function(gameData) return gameData.order end)
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
	local games = CustomPlayer._getGames()

	Array.extendWith(categories, Array.map(games, function (gameData)
		return gameData.category .. ' ' .. typeCategory .. 's'
	end))

	if #games == 0 then
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

function CustomPlayer:defineCustomPageVariables(args)
	-- isplayer and country needed for SMW
	if CustomPlayer._isNotPlayer(args.role) or CustomPlayer._isNotPlayer(args.role2) then
		Variables.varDefine('isplayer', 'false')
	else
		Variables.varDefine('isplayer', 'true')
	end

	Variables.varDefine('country', Player:getStandardNationalityValue(args.country or args.nationality))
end

function CustomPlayer:getPersonType(args)
	local roleData = _ROLES[(args.role or ''):lower()]
	if roleData then
		if roleData.coach then
			return { store = 'Staff', category = 'Coache' }
		elseif roleData.management then
			return { store = 'Staff', category = 'Manager' }
		elseif roleData.talent then
			return { store = '', category = 'Talent' }
		end
	end
	return { store = 'Player', category = 'Player' }
end

return CustomPlayer
