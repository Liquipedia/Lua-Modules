---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Namespace = require('Module:Namespace')
local OperatorIcon = require('Module:OperatorIcon')
local Page = require('Module:Page')
local Player = require('Module:Infobox/Person')
local PlayerTeamAuto = require('Module:PlayerTeamAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Builder = require('Module:Infobox/Widget/Builder')

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
		player.args.team = PlayerTeamAuto._main{}
	end

	if String.isEmpty(player.args.team2) then
		player.args.team2 = PlayerTeamAuto._main{team = 'team2'}
	end

	player.args.history = Template.safeExpand(frame, 'TeamHistoryAuto')

	player.args.informationType = player.args.informationType or 'Player'

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createBottomContent = CustomPlayer.createBottomContent
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables

	_args = player.args

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		local statusContents = CustomPlayer._getStatusContents()

		return {
			Cell{name = 'Status', content = statusContents},
			Cell{name = 'Years Active (Player)', content = {_args.years_active}},
			Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}},
			Cell{name = 'Time Banned', content = {_args.time_banned}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Current Role', content = {
					CustomPlayer._createRole('role', _args.role),
					CustomPlayer._createRole('role2', _args.role2)
				}},
		}
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
				Table.forEachPair(_GAMES,
					function(key)
						if _args[key] then
							table.insert(activeInGames, _GAMES[key])
						end
					end
				)
				return {
					Cell{
						name = #activeInGames > 1 and 'Games' or 'Game',
						content = {
							table.concat(activeInGames, '<br>')
						}
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
	lpdbData.extradata.isplayer = Variables.varDefault('isplayer')

	if String.isNotEmpty(_args.team2) then
		lpdbData.extradata.team2 = Team.page(_args.team2)
	end

	return lpdbData
end

function CustomPlayer:createBottomContent(infobox)
	if Namespace.isMain() then
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = _args.team}) ..
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = _args.team})
	end
end

function CustomPlayer._getStatusContents()
	local statusContents = {}
	local status
	if not String.isEmpty(_args.status) then
		status = Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status
	end
	table.insert(statusContents, status)

	local banned = _BANNED[string.lower(_args.banned or '')]
	if not banned and not String.isEmpty(_args.banned) then
		banned = '[[Banned Players|Multiple Bans]]'
		table.insert(statusContents, banned)
	end

	statusContents = Array.map(Player:getAllArgsForBase(_args, 'banned'),
		function(item, _)
			return _BANNED[string.lower(item)]
		end
	)

	return statusContents
end

function CustomPlayer._createRole(key, role)
	if String.isEmpty(role) then
		return nil
	end

	local roleData = _ROLES[role:lower()]
	if not roleData then
		return nil
	end
	if Namespace.isMain() then
		local categoryCoreText = 'Category:' .. roleData.category

		return '[[' .. categoryCoreText .. ']]' .. '[[:' .. categoryCoreText .. '|' ..
			Variables.varDefineEcho(key or 'role', roleData.variable) .. ']]'
	else
		return Variables.varDefineEcho(key or 'role', roleData.variable)
	end
end

function CustomPlayer:defineCustomPageVariables(args)
	-- isplayer needed for SMW
	if String.isNotEmpty(args.role) then
		local roleData = _ROLES[args.role:lower()]
		-- If the role is missing, assume it is a player
		if roleData and roleData.isplayer == false then
			Variables.varDefine('isplayer', 'false')
		else
			Variables.varDefine('isplayer', 'true')
		end
	end
end

return CustomPlayer
