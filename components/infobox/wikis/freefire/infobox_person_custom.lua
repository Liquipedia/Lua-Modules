---
-- @Liquipedia
-- wiki=freefire
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Page = require('Module:Page')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Region = require('Module:Region')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local _EMPTY_AUTO_HISTORY = '<table style="width:100%;text-align:left"></table>'

local _BANNED = {['banned'] = {category = 'Banned players', variable = 'Banned', isplayer = true},}

local _ROLES = {
	-- Players
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['rusher'] = {category = 'Rusher', variable = 'Rusher', isplayer = true},
	['sniper'] = {category = 'Snipers', variable = 'Snipers', isplayer = true},
	['lurker'] = {category = 'Lurkers', variable = 'Lurkers', isplayer = true},
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},

	-- [[Staff and Talents
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
	['admin'] = {category = 'Admins', variable = 'Admin', isplayer = false},--]]
}
_ROLES.lurk= _ROLES.lurker

local CustomPlayer = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local manualHistory = _args.history
		local automatedHistory = TeamHistoryAuto._results({
			convertrole = 'true',
			player = _pagename
		}) or ''
		automatedHistory = tostring(automatedHistory)
		if automatedHistory == _EMPTY_AUTO_HISTORY then
			automatedHistory = nil
		end

	if not (String.isEmpty(manualHistory) and String.isEmpty(automatedHistory)) then
			return {
				Title{name = 'History'}, Center{content = {manualHistory}},	Center{content = {automatedHistory}},
			      }
end
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._createRole('role', _args.role),
				CustomPlayer._createRole('role2', _args.role2)
			}},
		}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents()},
			Cell{name = 'Years Active (Player)', content = {_args.years_active}},
			Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
		}
		end
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.isplayer = Variables.varDefault('isplayer')
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {_args.country})

	if String.isNotEmpty(_args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(_args.team2).page
	end
	return lpdbData
end

function CustomPlayer._getStatusContents()
	local statusContents = {}

	if String.isNotEmpty(_args.status) then
		table.insert(statusContents, Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status)
	end

	if String.isNotEmpty(_args.banned) then
		local banned = _BANNED[string.lower(_args.banned)]
		table.insert(statusContents, banned)
		end
	return statusContents
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

function CustomPlayer._createRole(key, role)
	if String.isEmpty(role) then
		return nil
	end

	local roleData = _ROLES[role:lower()]
	if not roleData then
		return nil
	end
	if Player:shouldStoreData(_args) then
		local categoryCoreText = 'Category:' .. roleData.category

		return '[[' .. categoryCoreText .. ']]' .. '[[:' .. categoryCoreText .. '|' ..
			Variables.varDefineEcho(key or 'role', roleData.variable) .. ']]'
	else
		return Variables.varDefineEcho(key or 'role', roleData.variable)
end
end
	
return CustomPlayer