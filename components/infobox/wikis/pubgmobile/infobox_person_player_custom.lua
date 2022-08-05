---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Page = require('Module:Page')
local Class = require('Module:Class')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local PlayerTeamAuto = require('Module:PlayerTeamAuto')
local Role = require('Module:Role')
local Region = require('Module:Region')
local Team = require('Module:Team')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local _pagename = mw.title.getCurrentTitle().prefixedText
local _EMPTY_AUTO_HISTORY = '<table style="width:100%;text-align:left"></table>'

local _ROLES = {
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

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	if String.isEmpty(player.args.team) then
		player.args.team = PlayerTeamAuto._main{team = 'team'}
	end

	if String.isEmpty(player.args.team2) then
		player.args.team2 = PlayerTeamAuto._main{team = 'team2'}
	end

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables

	_args = player.args

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
				Title{name = 'History'},
				Center{content = {manualHistory}},
				Center{content = {automatedHistory}},
			}
		end
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents()},
			Cell{name = 'Years Active (Player)', content = {_args.years_active}},
			Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}},				
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}},			
		}
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._createRole('role', _args.role),
				CustomPlayer._createRole('role2', _args.role2)
			}},
		}
	end
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')

	lpdbData.type = Variables.varDefault('isplayer') == 'true' and 'player' or 'staff'

	if String.isNotEmpty(_args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(_args.team2).page
	end

	return lpdbData
end

function CustomPlayer._getStatusContents()
	if String.isEmpty(_args.status) then
		return {}
	end
	return {Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status}
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

function CustomPlayer:defineCustomPageVariables(args)
	-- isplayer needed for SMW
	local roleData
	if String.isNotEmpty(args.role) then
		roleData = _ROLES[args.role:lower()]
	end
	-- If the role is missing, assume it is a player
	if roleData and roleData.isplayer == false then
		Variables.varDefine('isplayer', 'false')
	else
		Variables.varDefine('isplayer', 'true')
	end
end

return CustomPlayer
