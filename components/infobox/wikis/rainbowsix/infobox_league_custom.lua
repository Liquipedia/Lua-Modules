---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Tier = require('Module:Tier')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local PageLink = require('Module:Page')

local _args
local _league

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _DEFAULT_TIERTYPE = 'General'
local _DEFAULT_PLATFORM = 'PC'
local _PLATFORM_ALIAS = {
	pc = 'PC',
	xbox = 'Xbox',
	xone = 'Xbox',
	['xbox one'] = 'Xbox',
	one = 'Xbox',
	playstation = 'Playstation',
	ps = 'Playstation',
	ps4 = 'Playstation',
}

local _GAMES = {
	siege = 'Siege',
	vegas2 = 'Vegas 2'
}

local _UBISOFT_TIERS = {
	si = 'Six Invitational',
	pl = 'Pro League',
	cl = 'Challenger League',
	national = 'National',
	major = 'Six Major',
	minor = 'Minor',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {(args.team_number or '') .. (args.team_slots and ('/' .. args.team_slots) or '')}
	})
	table.insert(widgets, Cell{
		name = 'Game',
		content = {CustomLeague:_createGameCell(args)}
	})
	table.insert(widgets, Cell{
		name = 'Platform',
		content = {CustomLeague:_createPlatformCell(args)}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _args
	if id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local game = String.isNotEmpty(args.game) and ('/' .. args.game) or ''
			local maps = {}

			for _, map in ipairs(_league:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(CustomLeague:_createNoWrappingSpan(
					PageLink.makeInternalLink({}, map, map .. game)
				)))
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'liquipediatier' then
		if CustomLeague:_validPublisherTier(args.ubisofttier) then
			table.insert(widgets,
				Cell{
					name = 'Ubisoft Tier',
					content = {'[['.._UBISOFT_TIERS[args.ubisofttier:lower()]..']]'},
					classes = {'valvepremier-highlighted'}
				}
			)
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(_league:getAllArgsForBase(args, 'map'), ';')

	if CustomLeague:_validPublisherTier(args.ubisofttier) then
		lpdbData.publishertier = args.ubisofttier:lower()
	end
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.liquipediatiertype = Tier.text.types[string.lower(args.liquipediatiertype or '')] or _DEFAULT_TIERTYPE
	lpdbData.extradata = {
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
		startdatetext = CustomLeague:_standardiseRawDate(args.sdate or args.date),
		enddatetext = CustomLeague:_standardiseRawDate(args.edate or args.date),
	}

	return lpdbData
end

function CustomLeague:_validPublisherTier(publishertier)
	return String.isNotEmpty(publishertier) and _UBISOFT_TIERS[publishertier:lower()]
end

function CustomLeague:_standardiseRawDate(dateString)
	-- Length 7 = YYYY-MM
	-- Length 10 = YYYY-MM-??
	if String.isEmpty(dateString) or (#dateString ~= 7 and #dateString ~= 10) then
		return ''
	end

	if #dateString == 7 then
		dateString = dateString .. '-??'
	end
	dateString = dateString:gsub('%-XX', '-??')
	return dateString
end

function CustomLeague:defineCustomPageVariables()
	-- Variables with different handling compared to commons
	Variables.varDefine(
		'tournament_liquipediatiertype',
		Tier.text.types[string.lower(_args.liquipediatiertype or '')] or _DEFAULT_TIERTYPE
	)

	--Legacy vars
	Variables.varDefine('tournament_ticker_name', _args.tickername or '')
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype')
	Variables.varDefine('tournament_prizepool', _args.prizepool or '')
	Variables.varDefine('tournament_mode', _args.mode or '')

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('date', edate)
	Variables.varDefine('sdate', sdate)
	Variables.varDefine('edate', edate)
end

function CustomLeague:getWikiCategories(args)
	local categories = {}
	if String.isNotEmpty(args.player_number) then
		table.insert(categories, 'Individual Tournaments')
	end

	if not CustomLeague:_gameLookup(args.game) then
		table.insert(categories, 'Tournaments without game version')
	else
		table.insert(categories, CustomLeague:_gameLookup(args.game) .. ' Competitions')
	end

	if CustomLeague:_platformLookup(args.platform) then
		table.insert(categories, CustomLeague:_platformLookup(args.platform) .. ' Tournaments')
	end

	return categories
end

function CustomLeague:_gameLookup(game)
	if String.isEmpty(game) then
		return nil
	end

	return _GAMES[game:lower()]
end

function CustomLeague:_platformLookup(platform)
	if String.isEmpty(platform) then
		platform = _DEFAULT_PLATFORM
	end

	return _PLATFORM_ALIAS[platform:lower()]
end

function CustomLeague:_createGameCell(args)
	if String.isEmpty(args.game) then
		return nil
	end

	local game = CustomLeague:_gameLookup(args.game)

	if String.isNotEmpty(game) then
		return '[['.. game ..']]'
	else
		return nil
	end
end

function CustomLeague:_createPlatformCell(args)
	local platform = CustomLeague:_platformLookup(args.platform)

	if String.isNotEmpty(platform) then
		return PageLink.makeInternalLink({}, platform, ':Category:'..platform)
	else
		return nil
	end
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
