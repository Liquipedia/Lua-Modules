---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Namespace = require('Module:Namespace')
local Variables = require('Module:Variables')
local Page = require('Module:Page')
local YearsActive = require('Module:YearsActive')
local Flags = require('Module:Flags')
local Localisation = require('Module:Localisation')
local Table = require('Module:Table')
local Array = require('Module:Array')
local HeroIcon = require('Module:HeroIcon')
local Template = require('Module:Template')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Builder = require('Module:Infobox/Widget/Builder')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local _BANNED = mw.loadData('Module:Banned')
local _ROLES = {
	-- Players
	['carry'] = {category = 'Carry players', variable = 'Carry', isplayer = true},
	['mid'] = {category = 'Solo middle players', variable = 'Solo Middle', isplayer = true},
	['solo middle'] = {category = 'Solo middle players', variable = 'Solo Middle', isplayer = true},
	['solomiddle'] = {category = 'Solo middle players', variable = 'Solo Middle', isplayer = true},
	['offlane'] = {category = 'Offlaners', variable = 'Offlaner', isplayer = true},
	['offlaner'] = {category = 'Offlaners', variable = 'Offlaner', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['captain'] = {category = 'Captains', variable = 'Captain', isplayer = true},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', isplayer = false},
	['observer'] = {category = 'Observers', variable = 'Observer', isplayer = false},
	['host'] = {category = 'Hosts', variable = 'Host', isplayer = false},
	['journalist'] = {category = 'Journalists', variable = 'Journalist', isplayer = false},
	['expert'] = {category = 'Experts', variable = 'Expert', isplayer = false},
	['coach'] = {category = 'Coaches', variable = 'Coach', isplayer = false},
	['caster'] = {category = 'Casters', variable = 'Caster', isplayer = false},
	['manager'] = {category = 'Managers', variable = 'Manager', isplayer = false},
	['streamer'] = {category = 'Streamers', variable = 'Streamer', isplayer = false},
}

local _ROLES_CATEGORY = {
	host = 'Casters',
	caster = 'Casters'
}
local _SIZE_HERO = '44x25px'

local _title = mw.title.getCurrentTitle()
local _base_page_name = _title.baseText
local _CONVERSION_PLAYER_ID_TO_STEAM = 61197960265728

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	-- Override links to allow one param to set multiple links
	player.args.datdota = player.args.playerid
	player.args.dotabuff = player.args.playerid
	player.args.stratz = player.args.playerid
	if not String.isEmpty(player.args.playerid) then
		player.args.steamalternative = '765' .. (tonumber(player.args.playerid) + _CONVERSION_PLAYER_ID_TO_STEAM)
	end

	_args = player.args
	player.args.informationType = player.args.informationType or 'Player'

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createBottomContent = CustomPlayer.createBottomContent
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		local statusContents = CustomPlayer._getStatusContents()

		local yearsActive = _args.years_active
		if String.isEmpty(yearsActive) then
			yearsActive = YearsActive.display({player = _base_page_name})
		else
			yearsActive = Page.makeInternalLink({onlyIfExists = true}, yearsActive)
		end

		local yearsActiveOrg = _args.years_active_manage
		if not String.isEmpty(yearsActiveOrg) then
			yearsActiveOrg = Page.makeInternalLink({onlyIfExists = true}, yearsActiveOrg)
		end

		return {
			Cell{name = 'Status', content = statusContents},
			Cell{name = 'Years Active (Player)', content = {yearsActive}},
			Cell{name = 'Years Active (Org)', content = {yearsActiveOrg}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {_args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {_args.years_active_talent}},
		}
	elseif id == 'history' then
		if not String.isEmpty(_args.history_iwo) then
			table.insert(widgets, Title{name = '[[Intel World Open|Intel World Open]] History'})
			table.insert(widgets, Center{content = {_args.history_iwo}})
		end
		if not String.isEmpty(_args.history_gfinity) then
			table.insert(widgets, Title{name = '[[Gfinity/Elite_Series|Gfinity Elite Series]] History'})
			table.insert(widgets, Center{content = {_args.history_gfinity}})
		end
		if not String.isEmpty(_args.history_odl) then
			table.insert(widgets, Title{name = '[[Oceania Draft League|Oceania Draft League]] History'})
			table.insert(widgets, Center{content = {_args.history_odl}})
		end
	elseif id == 'role' then
		return {
			Cell{name = 'Current Role', content = {
					CustomPlayer._createRole('role', _args.role),
					CustomPlayer._createRole('role2', _args.role2)
				}},
		}
	elseif id == 'nationality' then
		return {
			Cell{name = 'Nationality', content = CustomPlayer._createLocations()}
		}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets,
		Builder{
			builder = function()
				local heroes = Player:getAllArgsForBase(_args, 'hero')
				local icons = Array.map(heroes,
					function(h, _)
						return HeroIcon._getImage{hero = h, size = _SIZE_HERO}
					end
				)
				return {
					Cell{
						name = 'Signature Hero',
						content = {
							table.concat(icons, '&nbsp;')
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

function CustomPlayer:makeAbbr(title, text)
	if String.isEmpty(title) or String.isEmpty(text) then
		return nil
	end
	return '<abbr title="' .. title .. '>' .. text .. '</abbr>'
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.status = lpdbData.status or 'Unknown'

	lpdbData.extradata.role = Variables.varDefault('role')
	lpdbData.extradata.role2 = Variables.varDefault('role2')
	lpdbData.extradata.hero = _args.hero
	lpdbData.extradata.hero2 = _args.hero2
	lpdbData.extradata.hero3 = _args.hero3
	lpdbData.extradata['lc_id'] = _base_page_name:lower()
	lpdbData.extradata.team2 = mw.ext.TeamLiquidIntegration.resolve_redirect(
		not String.isEmpty(_args.team2link) and _args.team2link or _args.team2 or '')
	lpdbData.extradata.playerid = _args.playerid

	return lpdbData
end

function CustomPlayer:createBottomContent(infobox)
	if Namespace.isMain() then
		return tostring(Template.safeExpand(
			mw.getCurrentFrame(), 'Upcoming_and_ongoing_matches_of_player', {player = _base_page_name})
			.. '<br>' .. Template.safeExpand(
			mw.getCurrentFrame(), 'Upcoming_and_ongoing_tournaments_of_player', {player = _base_page_name})
		)
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

function CustomPlayer._createLocations()
	local countryDisplayData = {}
	local country = _args.country or _args.country1
	if String.isEmpty(country) then
		return countryDisplayData
	end

	return Table.mapValues(Player:getAllArgsForBase(_args, 'country'), CustomPlayer._createLocation)
end

function CustomPlayer._createLocation(country)
	if String.isEmpty(country) then
		return nil
	end
	local countryDisplay = Flags.CountryName(country)
	countryDisplay = '[[:Category:' .. countryDisplay .. '|' .. countryDisplay .. ']]'
	local demonym = Localisation.getLocalisation(countryDisplay)

	local roleCategory = _ROLES_CATEGORY[_args.role or ''] or 'Players'
	local role2Category = _ROLES_CATEGORY[_args.role2 or ''] or 'Players'

	local categories = ''
	if Namespace.isMain() then
		categories = '[[Category:' .. demonym .. ' ' .. roleCategory .. ']]'
		.. '[[Category:' .. demonym .. ' ' .. role2Category .. ']]'
	end

	return Flags.Icon({flag = country, shouldLink = true}) .. '&nbsp;' .. countryDisplay .. categories

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
	-- isplayer and country needed for SMW
	if String.isNotEmpty(args.role) then
		local roleData = _ROLES[args.role:lower()]
		-- If the role is missing, assume it is a player
		if roleData and roleData.isplayer == false then
			Variables.varDefine('isplayer', 'false')
		else
			Variables.varDefine('isplayer', 'true')
		end
	end

	Variables.varDefine('country', Player:getStandardNationalityValue(args.country or args.nationality))
end

return CustomPlayer
