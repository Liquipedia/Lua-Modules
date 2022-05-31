---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Page = require('Module:Page')
local Player = require('Module:Infobox/Person')
local PlayersSignatureAgents = require('Module:PlayersSignatureAgents')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Builder = require('Module:Infobox/Widget/Builder')

local _ROLES = {
	-- Players
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', isplayer = false},
	['observer'] = {category = 'Observers', variable = 'Observer', isplayer = false},
	['host'] = {category = 'Host', variable = 'Host', isplayer = false},
	['coach'] = {category = 'Coaches', variable = 'Coach', isplayer = false},
	['caster'] = {category = 'Casters', variable = 'Caster', isplayer = false},
	['manager'] = {category = 'Managers', variable = 'Manager', isplayer = false},
	['streamer'] = {category = 'Streamers', variable = 'Streamer', isplayer = false},
}
_ROLES['in-game leader'] = _ROLES.igl

local _SIZE_OPERATOR = '25x25px'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.args.history = tostring(TeamHistoryAuto._results{convertrole='true'})

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables

	_args = player.args

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents()},
			Cell{name = 'Years Active (Player)', content = {_args.years_active}},
			Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
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
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	-- Main Agents
	table.insert(widgets,
		Cell{
			name = 'Main Agents',
			content = {
				PlayersSignatureAgents.get{player = mw.title.getCurrentTitle().text}
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
	lpdbData.extradata.isplayer = Variables.varDefault('isplayer')

	lpdbData.extradata.agent1 = Variables.varDefault('agent1')
	lpdbData.extradata.agent2 = Variables.varDefault('agent2')
	lpdbData.extradata.agent3 = Variables.varDefault('agent3')

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {_args.country})

	return lpdbData
end

function CustomPlayer._getStatusContents()
	if String.isEmpty(_args.status) then
		return {}
	end
	return { Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status }
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
