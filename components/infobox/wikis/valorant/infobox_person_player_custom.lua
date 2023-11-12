---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local PlayersSignatureAgents = require('Module:PlayersSignatureAgents')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _ROLES = {
	-- Players
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', staff = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', variable = 'Broadcast Analyst', talent = true},
	['observer'] = {category = 'Observers', variable = 'Observer', talent = true},
	['host'] = {category = 'Host', variable = 'Host', talent = true},
	['journalist'] = {category = 'Journalists', variable = 'Journalist', talent = true},
	['expert'] = {category = 'Experts', variable = 'Expert', talent = true},
	['coach'] = {category = 'Coaches', variable = 'Coach', staff = true},
	['caster'] = {category = 'Casters', variable = 'Caster', talent = true},
	['manager'] = {category = 'Managers', variable = 'Manager', staff = true},
	['streamer'] = {category = 'Streamers', variable = 'Streamer', talent = true},
	['producer'] = {category = 'Production Staff', variable = 'Producer', talent = true},
	['director'] = {category = 'Production Staff', variable = 'Director', talent = true},
	['interviewer'] = {category = 'Interviewers', variable = 'Interviewer', talent = true},
}
_ROLES['in-game leader'] = _ROLES.igl

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _player
local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.args.history = TeamHistoryAuto._results{convertrole = 'true'}

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.getPersonType = CustomPlayer.getPersonType

	_args = player.args
	_args.autoTeam = true
	_player = player

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents()},
			Cell{name = 'Years Active (Player)', content = {_args.years_active}},
			Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._createRole('role', _args.role),
				CustomPlayer._createRole('role2', _args.role2)
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			content = {_args.retired}
		})
	elseif id == 'region' then
		return {}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	-- Main Agents
	table.insert(widgets,
		Cell{
			name = 'Main Agents',
			content = {
				PlayersSignatureAgents.get{player = _player.pagename}
			}
		}
	)
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')
	lpdbData.extradata.isplayer = CustomPlayer._isNotPlayer(_args.role) and 'false' or 'true'

	lpdbData.extradata.agent1 = Variables.varDefault('agent1')
	lpdbData.extradata.agent2 = Variables.varDefault('agent2')
	lpdbData.extradata.agent3 = Variables.varDefault('agent3')

	lpdbData.region = Region.name({region = _args.region, country = _args.country})

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

function CustomPlayer._isNotPlayer(role)
	local roleData = _ROLES[(role or ''):lower()]
	return roleData and (roleData.talent or roleData.staff)
end

function CustomPlayer:getPersonType(args)
	local roleData = _ROLES[(args.role or ''):lower()]
	if roleData then
		if roleData.staff then
			return {store = 'staff', category = 'Staff'}
		elseif roleData.talent then
			return {store = 'talent', category = 'Talent'}
		end
	end
	return {store = 'player', category = 'Player'}
end

return CustomPlayer
