---
-- @Liquipedia
-- wiki=rocketleague
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
local Matches = require('Module:Matches_Player')
local Flags = require('Module:Flags')
local Localisation = require('Module:Localisation')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local _BANNED = mw.loadData('Module:Banned')

local _title = mw.title.getCurrentTitle()
local _pagename = _title.prefixedText
local _base_page_name = _title.baseText

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	_player = player
	player.args.informationType = player.args.informationType or 'Player'

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.createBottomContent = CustomPlayer.createBottomContent
	player.getCategories = CustomPlayer.getCategories
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		local statusContents = CustomPlayer._getStatusContents()

		local yearsActive = _args.years_active
		if String.isEmpty(yearsActive) then
			yearsActive = YearsActive.get({player = _base_page_name})
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
			Cell{name = 'Current Role', content = {_args.role}},
		}
	elseif id == 'nationality' then
		return {
			Cell{name = 'Location', content = {_args.location}},
			Cell{name = 'Nationality', content = CustomPlayer._createLocations()}
		}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	local gameDisplay = string.lower(_args.game or '')
	if gameDisplay == 'sarpbc' then
		gameDisplay = '[[SARPBC]]'
	else
		gameDisplay = '[[Rocket League]]'
	end

	local mmrDisplay
	if not String.isEmpty(_args.mmr) then
		mmrDisplay = '[[Leaderboards|' .. _args.mmr .. ']]'
		if not String.isEmpty(_args.mmrdate) then
			mmrDisplay = mmrDisplay .. '&nbsp;<small>\'\'('
				.. _args.mmrdate .. ')\'\'</small>'
		end
	end

	return {
		Cell{
			name = CustomPlayer:makeAbbr(
				'Support-A-Creator Code used when purchasing Rocket League or Epic Games Store products',
				'Epic Creator Code'
			),
			content = {_args.creatorcode}
		},
		Cell{name = 'Starting Game', content = {gameDisplay}},
		Cell{name = 'Solo MMR', content = {mmrDisplay}},
	}
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

function CustomPlayer:getCategories(args, birthDisplay, personType, status)
	if Namespace.isMain() then
		local role = string.lower(args.role or '')
		local categories = {}

		if string.match(role, 'coach') then
			table.insert(categories, 'Coaches')
		end
		if string.match(role, 'caster') then
			table.insert(categories, 'Casters')
		end
		if string.match(role, 'host') then
			table.insert(categories, 'Hosts')
		end

		if string.match(role, 'player') then
			table.insert(categories, 'Players')

			if
				string.lower(args.status) == 'active' and
				not args.teamlink and not args.team
			then
				table.insert(categories, 'Teamless Players')
			end

			if String.isEmpty(args.status) then
				table.insert(categories, 'Players without a status')
			end
		end

		local personTypeSuffix = 's'
		if personType == 'Coach' then
			personTypeSuffix = 'es'
		end

		--_player
		if
			not _player.nonRepresenting and (args.country2 or args.nationality2)
			or args.country3
			or args.nationality3
		then
			table.insert(categories, 'Dual Citizenship ' .. personType .. personTypeSuffix)
		end
		if args.death_date then
			table.insert(categories, 'Deceased ' .. personType .. personTypeSuffix)
		end

		if
			args.retired == 'yes' or args.retired == 'true'
			or string.lower(status or '') == 'retired'
			or string.match(args.retired or '', '%d%d%d%d')--if `|retired` has year set
		then
			table.insert(categories, 'Retired ' .. personType .. personTypeSuffix)
		end

		if not args.image then
			table.insert(categories, personType .. personTypeSuffix .. ' with no profile picture')
		end

		if String.isEmpty(birthDisplay) then
			table.insert(categories, personType .. personTypeSuffix .. ' with unknown birth date')
		end

		if string.lower(args.game or '') == 'sarpbc' then
			table.insert(categories, 'SARPBC Players')
		end

		local team = args.teamlink or args.team
		if team and not mw.ext.TeamTemplate.teamexists(team) then
			table.insert(categories, 'Players with invalid team')
		end

		return categories
	end
	return {}
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.status = lpdbData.status or 'Unknown'

	lpdbData.extradata.role = _args.role
	lpdbData.extradata.birthmonthandday = Variables.varDefault('birth_monthandday')

	return lpdbData
end

function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('id', args.id or _pagename)

	--retrieve birth month + day for storage in smw
	local birthMonthAndDay = string.match(args.birth_date or '', '%-%d%d?%-%d%d?$')
	birthMonthAndDay = string.gsub(birthMonthAndDay or '', '^%-', '')
	Variables.varDefine('birth_monthandday', birthMonthAndDay)
end

function CustomPlayer:createBottomContent(infobox)
	if Namespace.isMain() then
		return tostring(Matches.get({args = {noClass = true}}))
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
		banned = '[[Banned Players/Other|Multiple Bans]]'
		table.insert(statusContents, banned)
	end

	local index = 2
	banned = _BANNED[string.lower(_args['banned' .. index] or '')]
	while banned do
		table.insert(statusContents, banned)
		index = index + 1
		banned = _BANNED[string.lower(_args['banned' .. index] or '')]
	end

	return statusContents
end

function CustomPlayer._createLocations()
	local countryDisplayData = {}
	local country = _args.country or _args.country1
	if String.isEmpty(country) then
		return countryDisplayData
	end

	countryDisplayData[1] = CustomPlayer:_createLocation(country)

	local index = 2
	country = _args['country2']
	while (not String.isEmpty(country)) do
		countryDisplayData[index] = CustomPlayer:_createLocation(country)
		index = index + 1
		country = _args['country' .. index]
	end

	return countryDisplayData
end

function CustomPlayer:_createLocation(country)
	if String.isEmpty(country) then
		return nil
	end
	local countryDisplay = Flags.CountryName(country)
	local demonym = Localisation.getLocalisation(countryDisplay)

	return Flags.Icon({flag = country, shouldLink = true}) .. '&nbsp;' ..
				'[[:Category:' .. countryDisplay .. '|' .. countryDisplay .. ']]'
				.. '[[Category:' .. demonym .. ' Players]]'
end


return CustomPlayer
