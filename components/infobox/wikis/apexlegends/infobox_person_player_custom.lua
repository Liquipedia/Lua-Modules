---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Page = require('Module:Page')
local Class = require('Module:Class')
local LegendIcon = require('Module:LegendIcon')
local Player = require('Module:Infobox/Person')
local PlayerTeamAuto = require('Module:PlayerTeamAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Builder = require('Module:Infobox/Widget/Builder')

local _INPUTS = {
	controller = 'Controller',
	cont = 'Controller',
	c = 'Controller',
	default = 'Mouse & Keyboard',
}

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
local _SIZE_LEGEND = '25x25px'

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

	player.args.history = tostring(TeamHistoryAuto._results{addlpdbdata='true'})

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createBottomContent = CustomPlayer.createBottomContent
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables

	_args = player.args

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'region' then
		return {}
	elseif id == 'status' then
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
	-- Signature Legends
	table.insert(widgets,
		Builder{
			builder = function()
				local legendIcons = Array.map(Player:getAllArgsForBase(_args, 'legends'),
					function(legend, _)
						return LegendIcon.getImage{legend, size = _SIZE_LEGEND}
					end
				)
				return {
					Cell{
						name = #legendIcons > 1 and 'Signature Legends' or 'Signature Legend',
						content = {
							table.concat(legendIcons, '&nbsp;')
						}
					}
				}
			end
		})
	table.insert(widgets, Cell{
			name = 'Input',
			content = {_INPUTS[_args.input] or _INPUTS.default}
		})
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')

	_args.legend1 = _args.legend1 or _args.legend
	for _, legend, legendIndex in Table.iter.pairsByPrefix(_args, 'legend') do
		lpdbData.extradata['signatureLegend' .. legendIndex] = legend
	end
	lpdbData.type = Variables.varDefault('isplayer') == 'true' and 'player' or 'staff'

	if String.isNotEmpty(_args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(_args.team2).page
	end

	return lpdbData
end

function CustomPlayer:createBottomContent(infobox)
	if Player:shouldStoreData(_args) and String.isNotEmpty(_args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(),_args.team)
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
	end
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
