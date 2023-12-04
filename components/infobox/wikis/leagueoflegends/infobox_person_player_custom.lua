---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _ROLES = {
	-- Players
	['top'] = {category = 'Top Lane players', variable = 'Top', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['jungle'] = {category = 'Jungle players', variable = 'Jungle', isplayer = true},
	['mid'] = {category = 'Mid Lane players', variable = 'Mid', isplayer = true},
	['bottom'] = {category = 'Bot Lane players', variable = 'Bot', isplayer = true},

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
	['streamer'] = {category = 'Streamers', variable = 'Streamer', isplayer = false},
}
_ROLES['assistant coach'] = _ROLES.coach
_ROLES['strategic coach'] = _ROLES.coach
_ROLES['positional coach'] = _ROLES.coach
_ROLES['head coach'] = _ROLES.coach
_ROLES['jgl'] = _ROLES.jungle
_ROLES['solomiddle'] = _ROLES.mid
_ROLES['carry'] = _ROLES.bottom
_ROLES['adc'] = _ROLES.bottom
_ROLES['bot'] = _ROLES.bottom
_ROLES['ad carry'] = _ROLES.bottom
_ROLES['sup'] = _ROLES.support

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	if String.isEmpty(player.args.history) then
		player.args.history = TeamHistoryAuto._results{
			hiderole = 'true',
			iconModule = 'Module:PositionIcon/data',
			addlpdbdata = 'true'
		}
	end

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createBottomContent = CustomPlayer.createBottomContent
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	_args = player.args
	_args.autoTeam = true

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		local status = _args.status
		if String.isNotEmpty(status) then
			status = mw.getContentLanguage():ucfirst(status)
		end

		return {
			Cell{name = 'Status', content = {Page.makeInternalLink({onlyIfExists = true},
						status) or status}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._createRole('role', _args.role),
				CustomPlayer._createRole('role2', _args.role2),
				CustomPlayer._createRole('role3', _args.role3)
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			content = {_args.retired}
		})
	end
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')
	lpdbData.extradata.role3 = Variables.varDefault('role3')

	lpdbData.extradata.signatureChampion1 = _args.champion1 or _args.champion
	lpdbData.extradata.signatureChampion2 = _args.champion2
	lpdbData.extradata.signatureChampion3 = _args.champion3
	lpdbData.extradata.signatureChampion4 = _args.champion4
	lpdbData.extradata.signatureChampion5 = _args.champion5
	lpdbData.type = CustomPlayer._isPlayerOrStaff()

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {_args.country})

	if String.isNotEmpty(_args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(_args.team2).page
	end

	return lpdbData
end

function CustomPlayer:createBottomContent(infobox)
	if Player:shouldStoreData(_args) and String.isNotEmpty(_args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(),_args.team)
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}) ..
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
	end
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

function CustomPlayer._isPlayerOrStaff()
	local roleData
	if String.isNotEmpty(_args.role) then
		roleData = _ROLES[_args.role:lower()]
	end
	-- If the role is missing, assume it is a player
	if roleData and roleData.isplayer == false then
		return 'staff'
	else
		return 'player'
	end
end

return CustomPlayer
