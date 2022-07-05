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
local HeroNames = mw.loadData('Module:HeroNames')
local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local GameAppearances = require('Module:GetGameAppearances')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

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

local _SIZE_HERO = '25x25px'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _pagename = mw.title.getCurrentTitle().prefixedText
local _args
local _player

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.args.history = tostring(TeamHistoryAuto._results{addlpdbdata='true'})

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables

	_args = player.args
	_player = player

	return player:createInfobox(frame)
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'role' then
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
	local heroIcons = Array.map(Player:getAllArgsForBase(_args, 'hero'),
		function(hero)
			local standardizedHero = HeroNames[hero:lower()]
			if not standardizedHero then
				-- we have an invalid hero entry
				-- add warning (including tracking category)
				table.insert(
					_player.warnings,
					'Invalid hero input "' .. hero .. '"[[Category:Pages with invalid hero input]]'
				)
			end
			return HeroIcon.getImage{standardizedHero or hero, size = _SIZE_HERO}
		end
	)

	if Table.isNotEmpty(heroIcons) then
		table.insert(widgets,
			Cell{
				name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
				content = {
					table.concat(heroIcons, '&nbsp;')
				}
			}
		)
	end

	-- Active in Games
	Cell{
		name = 'Game Appearances',
		content = GameAppearances.player({ player = _pagename })
	}
	return widgets
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')

	mw.logObject(_args)
	-- store signature heroes with standardized name
	for heroIndex, hero in ipairs(Player:getAllArgsForBase(_args, 'hero')) do
		lpdbData.extradata['signatureHero' .. heroIndex] = hero
	end

	lpdbData.type = Variables.varDefault('isplayer') == 'true' and 'player' or 'staff'

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {_args.country})

	if String.isNotEmpty(_args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(_args.team2).page
	end

	return lpdbData
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
