---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local OperatorIcon = require('Module:OperatorIcon')
local Page = require('Module:Page')
local PlayerTeamAuto = require('Module:PlayerTeamAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Builder = Widgets.Builder
local Cell = Widgets.Cell

local _BANNED = mw.loadData('Module:Banned')
local _ROLES = {
	-- Players
	['entry'] = {category = 'Entry fraggers', variable = 'Entry fragger', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['flex'] = {category = 'Flex players', variable = 'Flex', isplayer = true},
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},

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
_ROLES.entryfragger = _ROLES.entry
_ROLES['assistant coach'] = _ROLES.coach

local _GAMES = {
	r6s = '[[Rainbow Six Siege|Siege]]',
	vegas2 = '[[Rainbow Six Vegas 2|Vegas 2]]',
}
_GAMES.siege = _GAMES.r6s

local _SIZE_OPERATOR = '25x25px'

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
	if id == 'status' then
		return {
			Cell{name = 'Status', content = CustomPlayer._getStatusContents()},
			Cell{name = 'Years Active (Player)', content = {_args.years_active}},
			Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}},
			Cell{name = 'Time Banned', content = {_args.time_banned}},
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
	-- Signature Operators
	table.insert(widgets,
		Builder{
			builder = function()
				local operatorIcons = Array.map(Player:getAllArgsForBase(_args, 'operator'),
					function(operator, _)
						return OperatorIcon.getImage{operator, size = _SIZE_OPERATOR}
					end
				)
				return {
					Cell{
						name = #operatorIcons > 1 and 'Signature Operators' or 'Signature Operator',
						content = {
							table.concat(operatorIcons, '&nbsp;')
						}
					}
				}
			end
		})
	-- Active in Games
	table.insert(widgets,
		Builder{
			builder = function()
				local activeInGames = {}
				Table.iter.forEachPair(_GAMES,
					function(key)
						if _args[key] then
							table.insert(activeInGames, _GAMES[key])
						end
					end
				)
				return {
					Cell{
						name = #activeInGames > 1 and 'Games' or 'Game',
						content = activeInGames
					}
				}
			end
		})
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')

	lpdbData.extradata.signatureOperator1 = _args.operator1 or _args.operator
	lpdbData.extradata.signatureOperator2 = _args.operator2
	lpdbData.extradata.signatureOperator3 = _args.operator3
	lpdbData.extradata.signatureOperator4 = _args.operator4
	lpdbData.extradata.signatureOperator5 = _args.operator5
	lpdbData.type = Variables.varDefault('isplayer') == 'true' and 'player' or 'staff'

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

function CustomPlayer._getStatusContents()
	local statusContents = {}

	if String.isNotEmpty(_args.status) then
		table.insert(statusContents, Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status)
	end

	local banned = _BANNED[string.lower(_args.banned or '')]
	if not banned and String.isNotEmpty(_args.banned) then
		banned = '[[Banned Players|Multiple Bans]]'
		table.insert(statusContents, banned)
	end

	return Array.extendWith(statusContents,
		Array.map(Player:getAllArgsForBase(_args, 'banned'),
			function(item, _)
				return _BANNED[string.lower(item)]
			end
		)
	)
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
