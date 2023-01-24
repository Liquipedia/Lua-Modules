---
-- @Liquipedia
-- wiki=freefire
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:lua')
local String = require('Module:StringUtils')
local Page = require('Module:Page')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _EMPTY_AUTO_HISTORY = '<table style="width:100%;text-align:left"></table>'

local _ROLES = {
	-- Players
	support = {category = 'Support players', variable = 'Support', isplayer = true},
	rusher = {category = 'Rusher', variable = 'Rusher', isplayer = true},
	sniper = {category = 'Snipers', variable = 'Snipers', isplayer = true},
	granader = {category = 'Granader', variable = 'Granader', isplayer = true},
	igl = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},
	captain = {category = 'Captain', variable = 'Captain', isplayer = true},

	--Staff and Talents
	analyst = {category = 'Analysts', variable = 'Analyst', staff = true},
	coach = {category = 'Coaches', variable = 'Coach', staff = true},
	['assistant coach'] = {category = 'Assistant Coach ', variable = 'Assistant Coach', staff = true},
	manager = {category = 'Managers', variable = 'Manager', staff = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', variable = 'Broadcast Analyst', talent = true},
	host = {category = 'Hosts', variable = 'Host', talent = true},
	journalist = {category = 'Journalists', variable = 'Journalist', talent = true},
	caster = {category = 'Casters', variable = 'Caster', talent = true},
	commentator = {category = 'Commentators', variable = 'Commentator', talent = true},
	producer = {category = 'Producers', variable = 'Producer', talent = true},
	streamer = {category = 'Streamers', variable = 'Streamer', talent = true},
	interviewer = {category = 'Interviewers', variable = 'Interviewer', talent = true},
}

local CustomPlayer = Class.new()
local CustomInjector = Class.new(Injector)
local _pagename = mw.title.getCurrentTitle().prefixedText
local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.getPersonType = CustomPlayer.getPersonType
	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
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

		if String.isNotEmpty(manualHistory) or String.isNotEmpty(automatedHistory) then
			return {
				Title{name = 'History'},
				Center{content = {manualHistory}},
				Center{content = {automatedHistory}},
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
			Cell{name = 'Years Active (Analyst)', content = {_args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}},
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

	local team2 = _args.team2link or _args.team2
	if String.isNotEmpty(team2) then
		lpdbData.extradata.team2 = (mw.ext.TeamTemplate.raw(team2) or {}).page or team2
	end
	return lpdbData
end

function CustomPlayer._getStatusContents()
	if String.isEmpty(_args.status) then
		return {}
	end
	return {Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status}
end

function CustomPlayer._isNotPlayer(role)
	local roleData = _ROLES[(role or ''):lower()]
	return roleData and (roleData.talent or roleData.staff)
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
		if roleData.staff then
			return {store = 'Staff', category = 'Staff'}
		elseif roleData.talent then
			return {store = 'Talent', category = 'Talent'}
		end
	end
	return {store = 'Player', category = 'Player'}
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
