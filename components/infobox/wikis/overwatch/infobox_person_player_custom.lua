---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local HeroIcon = require('Module:HeroIcon')
local Page = require('Module:Page')
local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')
local PositionIcon = require('Module:PositionIcon/data')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Builder = require('Module:Infobox/Widget/Builder')

local _BANNED = mw.loadData('Module:Banned')
local _ROLES = {
	-- Players
	-- TODO adjust player roles to be relevant to OW
	['dps'] = {category = 'DPS Players', variable = 'DPS', isplayer = true},
	['flex'] = {category = 'Flex Players', variable = 'Flex', isplayer = true},
	['support'] = {category = 'Support Players', variable = 'Support', isplayer = true},
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader', isplayer = true},
	['tank'] = {category = 'Tank Players', variable = 'Tank', isplayer = true},

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
_ROLES['assistant coach'] = _ROLES.coach

local _GAMES = {
	ow2 = '[[Overwatch 2]]',
	ow = '[[Overwatch]]',
}

local _SIZE_HERO = '25x25px'
local _SIZE_ROLE = '25x25px'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.args.history = tostring(TeamHistoryAuto._results{addlpdbdata='true'})

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createBottomContent = CustomPlayer.createBottomContent
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables

	_args = player.args

	return player:createInfobox(frame)
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
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
	-- Signature Heroes
	table.insert(widgets,
		Builder{
			builder = function()
				local heroIcons = Array.map(Player:getAllArgsForBase(_args, 'hero'),
					function(hero, _)
						return HeroIcon.getImage{hero, size = _SIZE_HERO}
					end
				)
				return {
					Cell{
						name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
						content = {
							table.concat(heroIcons, '&nbsp;')
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

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')

	lpdbData.extradata.signatureHero1 = _args.hero1 or _args.hero
	lpdbData.extradata.signatureHero2 = _args.hero2
	lpdbData.extradata.signatureHero3 = _args.hero3
	lpdbData.type = Variables.varDefault('isplayer') == 'true' and 'player' or 'staff'

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

	if _args.type == 'player' then
        local roleName = roleData.variable:lower()
        return PositionIcon.roleName .. roleData
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
