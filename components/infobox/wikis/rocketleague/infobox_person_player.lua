---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Person/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Player = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Earnings = require('Module:Earnings')
local Namespace = require('Module:Namespace')
local Variables = require('Module:Variables')
local Page = require('Module:Page')
local YearsActive = require('Module:YearsActive')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local _BANNED = mw.loadData('Module:Banned')

local _pagename = mw.title.getCurrentTitle().prefixedText

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

local _START_YEAR = '2015'
local _CURRENT_YEAR = mw.getContentLanguage():formatDate('Y')

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	player.args.informationType = player.args.informationType or 'Player'

	player.calculateEarnings = CustomPlayer.calculateEarnings
	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.getCategories = CustomPlayer.getCategories
	player.getPersonType = CustomPlayer.getPersonType --for RL kick this
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		local statusContents = {}
		local status
		if not String.isEmpty(_args.status) then
			status = Page.makeInternalLink({onlyIfExists = true}, _args.status)
		end
		local banned = _BANNED[string.lower(_args.banned or '')]
		if not banned and not String.isEmpty(_args.banned) then
			banned = '[[Banned Players/Other|Multiple Bans]]'
		end
		local banned2 = _BANNED[string.lower(_args.banned2 or '')]
		local banned3 = _BANNED[string.lower(_args.banned3 or '')]
		table.insert(statusContents, status)
		table.insert(statusContents, banned)
		table.insert(statusContents, banned2)
		table.insert(statusContents, banned3)

		local yearsActive = _args.years_active
		if String.isEmpty(yearsActive) then
			yearsActive = YearsActive.get({player=mw.title.getCurrentTitle().baseText})
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

function CustomPlayer:calculateEarnings()
	return Earnings.calc_player({ args = {
		player = _args.earnings or _pagename,
	}})
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
		end

		if
			role == 'player' and
			string.lower(args.status) == 'active' and
			not args.teamlink and not args.team
		then
			table.insert(categories, 'Teamless ' .. personType .. 's')
		end

		if args.country2 or args.nationality2 then
			table.insert(categories, 'Dual Citizenship ' .. personType .. 's')
		end
		if args.death_date then
			table.insert(categories, 'Deceased ' .. personType .. 's')
		end

		if
			args.retired == 'yes' or args.retired == 'true'
			or string.lower(status or '') == 'retired'
			or string.match(args.retired or '', '%d%d%d%d')--if retired has year set apply the retired category
		then
			table.insert(categories, 'Retired ' .. personType .. 's')
		end

		if not args.image then
			table.insert(categories, personType .. 's with no profile picture')
		end

		if String.isEmpty(birthDisplay) then
			table.insert(categories, personType .. 's with unknown birth date')
		end

		if role == 'player' and String.isEmpty(args.status) then
			table.insert(categories, 'Players without a status')
		end

		if string.lower(args.game or '') == 'sarpbc' then
			table.insert(categories, 'SARPBC Players')
		end

		return categories
	end
	return {}
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.status = lpdbData.status or 'Unknown'

	lpdbData.extradata = {
		role = _args.role,
		birthmonthandday = Variables.varDefault('birth_monthandday'),
	}

	for year = _START_YEAR, _CURRENT_YEAR do
		lpdbData.extradata['earningsin' .. year] = Earnings.calc_player({args = {
			player = _args.earnings or _pagename,
			year = year
		}})
	end

	return lpdbData
end

function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('id', args.id or _pagename)

	--retrieve birth month + day for storage in smw
	local birthMonthAndDay = string.match(_args.birth_date, '%-%d%d?%-%d%d?$')
	birthMonthAndDay = string.gsub(birthMonthAndDay, '^%-', '')
	Variables.varDefine('birth_monthandday', birthMonthAndDay)
end

return CustomPlayer
