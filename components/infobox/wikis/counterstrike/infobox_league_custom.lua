---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local League = require('Module:Infobox/League')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Tier = mw.loadData('Module:Tier')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Cell = require('Module:Infobox/Widget/Cell')
local Injector = require('Module:Infobox/Widget/Injector')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local GAMES = {
	cs16 = {name = 'Counter-Strike', link = 'Counter-Strike', category = 'CS1.6 Competitions'},
	cscz = {name = 'Condition Zero', link = 'Counter-Strike: Condition Zero', category = 'CSCZ Competitions'},
	css = {name = 'Source', link = 'Counter-Strike: Source', category = 'CSS Competitions'},
	cso = {name = 'Online', link = 'Counter-Strike Online', category = 'CSO Competitions'},
	csgo = {name = 'Global Offensive', link = 'Counter-Strike: Global Offensive', category = 'CSGO Competitions'},
}

local ESL_PRO_TIERS_SIZE = '40x40px'
local ESL_PRO_TIERS = {
	['national challenger'] = {
		icon = 'ESL Pro Tour Challenger.png',
		name = 'National Champ.',
		link = 'ESL National Championships'
	},
	['international challenger'] = {
		icon = 'ESL Pro Tour Challenger.png',
		name = 'Challenger',
		link = 'ESL Pro Tour'
	},
	['regional challenger'] = {
		icon = 'ESL Pro Tour Challenger.png',
		name = 'Regional Challenger',
		link = 'ESL/Pro Tour'
	},
	['masters'] = {
		icon = 'ESL Pro Tour Masters.png',
		name = 'Masters',
		link = 'ESL/Pro Tour'
	},
	['regional masters'] = {
		icon = 'ESL Pro Tour Masters.png',
		name = 'Regional Masters',
		link = 'ESL/Pro Tour'
	},
	['masters championship'] = {
		icon = 'ESL Pro Tour Masters Championship.png',
		name = 'Masters Champ.',
		link = 'ESL Pro Tour'
	},
	['major championship'] = {
		icon = 'Valve csgo tournament icon.png',
		name = 'Major Championship',
		link = 'Majors'
	},
}
ESL_PRO_TIERS['national championship'] = ESL_PRO_TIERS['national challenger']
ESL_PRO_TIERS['challenger'] = ESL_PRO_TIERS['international challenger']

local VALVE_TIERS = {
	['major'] = {meta = 'Major Championship', name = 'Major Championship', link = 'Majors'},
	['major qualifier'] = {meta = 'Major Championship main qualifier', name = 'Major Qualifier', link = 'Majors'},
	['minor'] = {meta = 'Regional Minor Championship', name = 'Minor Championship', link = 'Minors'},
	['rmr event'] = {meta = 'Regional Major Rankings evnt', name = 'RMR Event', link = 'Regional Major Rankings'},
}

local _DATE_TBA = 'tba'

local _TIER_VALVE_MAJOR = 'major'

local _MODE_1v1 = '1v1'
local _MODE_TEAM = 'team'

local _args

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	_args['publisherdescription'] = 'metadesc-valve'
	_args.liquipediatier = Tier.number[_args.liquipediatier]

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {(_args.team_number or '') .. (_args.team_slots and ('/' .. _args.team_slots) or '')}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {_args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then
		if String.isNotEmpty(_args.map1) then
			local game = String.isNotEmpty(_args.game) and ('/' .. _args.game) or ''
			local maps = {}

			for _, map in ipairs(League:getAllArgsForBase(_args, 'map')) do
				table.insert(maps, tostring(CustomLeague:_createNoWrappingSpan(
					Page.makeInternalLink({}, map, map .. game)
				)))
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize Pool',
				content = {CustomLeague:_createPrizepool(_args)}
			},
		}
	elseif id == 'liquipediatier' then
		table.insert(
			widgets,
			Cell{
				name = '[[File:ESL 2019 icon.png|20x20px|link=|ESL|alt=ESL]] Pro Tour Tier',
				content = {CustomLeague:_createEslProTierCell(_args.eslprotier)},
				classes = {'infobox-icon-small'}
			}
		)
		table.insert(
			widgets,
			Cell{
				name = Template.safeExpand(mw.getCurrentFrame(), 'Valve/infobox') .. ' Tier',
				content = {CustomLeague:_createValveTierCell(_args.valvetier)},
				classes = {'valvepremier-highlighted'}
			}
		)
	elseif id == 'gamesettings' then
		return {
			Cell{
				name = 'Game',
				content = {CustomLeague:_createGameCell(_args)}
			}
		}
	end

	return widgets
end

function CustomLeague:getWikiCategories(args)
	local categories = {}

	if CustomLeague.getGame() then
		table.insert(categories, CustomLeague.getGame().category)
	end

	if String.isEmpty(args.game) then
		table.insert(categories, 'Tournaments without game version')
	end

	if not Logic.readBool(args.cancelled) and
		(String.isNotEmpty(args.prizepool) and args.prizepool ~= 'Unknown') and
		String.isEmpty(args.prizepoolusd) then
		table.insert(categories, 'Infobox league lacking prizepoolusd')
	end

	if String.isNotEmpty(args.prizepool) and String.isEmpty(args.localcurrency) then
		table.insert(categories, 'Infobox league lacking localcurrency')
	end

	if String.isNotEmpty(args.sort_date) then
		table.insert(categories, 'Tournaments with custom sort date')
	end

	if String.isNotEmpty(args.eslprotier) then
		table.insert(categories, 'ESL Pro Tour Tournaments')
	end

	if String.isNotEmpty(args.valvetier) then
		table.insert(categories, 'Valve Sponsored Tournaments')
	end

	return categories
end

function CustomLeague:liquipediaTierHighlighted(args)
	return String.isEmpty(args.valvetier) and Logic.readBool(args.valvemajor)
end

function CustomLeague:appendLiquipediatierDisplay()
	local content = ''

	if String.isEmpty(_args.valvetier) and Logic.readBool(_args.valvemajor) then
		content = content .. ' [[File:Valve_logo_black.svg|x12px|link=Valve_icon.png|x16px|' ..
			'link=Counter-Strike Majors|Counter-Strike Major]]'
	end

	if Logic.readBool(_args.cstrikemajor) then
		content = content .. ' [[File:cstrike-icon.png|x16px|link=Counter-Strike Majors|Counter-Strike Major]]'
	end

	return content
end

function CustomLeague:_createPrizepool(args)
	if String.isEmpty(args.prizepool) and String.isEmpty(args.prizepoolusd) then
		return nil
	end

	local content
	local prizepool = args.prizepool
	local prizepoolInUsd = args.prizepoolusd
	local localCurrency = args.localcurrency

	if String.isEmpty(prizepool) then
		content = '$' .. (prizepoolInUsd) .. ' ' .. Template.safeExpand(mw.getCurrentFrame(), 'Abbr/USD')
	else
		if String.isNotEmpty(localCurrency) then
			content = Template.safeExpand(
				mw.getCurrentFrame(),
				'Local currency',
				{localCurrency:lower(), prizepool = prizepool}
			)
			Variables.varDefine('prizepoollocal', content)
		else
			content = prizepool
		end

		if String.isNotEmpty(prizepoolInUsd) then
			content = content .. '<br>(≃ $' .. prizepoolInUsd .. ' ' ..
				Template.safeExpand(mw.getCurrentFrame(), 'Abbr/USD') .. ')'
		end
	end

	if String.isNotEmpty(prizepoolInUsd) then
		Variables.varDefine('tournament_prizepoolusd', prizepoolInUsd:gsub(',', ''):gsub('$', ''))
	else
		Variables.varDefine('tournament_prizepoolusd', 0)
	end

	return content
end

function CustomLeague:defineCustomPageVariables(args)
	-- Legacy vars
	Variables.varDefine('tournament_short_name', args.shortname)
	Variables.varDefine('tournament_ticker_name', args.tickername or args.name)
	Variables.varDefine('tournament_icon_darkmode', Variables.varDefault('tournament_icondark'))

	if String.isNotEmpty(args.date) and args.date:lower() ~= _DATE_TBA then
		Variables.varDefine('date', ReferenceCleaner.clean(args.date))
	end

	if String.isNotEmpty(args.sdate) and args.sdate:lower() ~= _DATE_TBA then
		Variables.varDefine('sdate', ReferenceCleaner.clean(args.sdate))
		Variables.varDefine('tournament_sdate', ReferenceCleaner.clean(args.sdate or args.date))
	end

	if String.isNotEmpty(args.edate) and args.edate:lower() ~= _DATE_TBA then
		local cleandDate = ReferenceCleaner.clean(args.edate or args.date)
		Variables.varDefine('edate', ReferenceCleaner.clean(args.edate))
		Variables.varDefine('tournament_date', cleandDate)
		Variables.varDefine('tournament_edate', cleandDate)
	end

	-- Legacy tier vars
	Variables.varDefine('tournament_tier', Tier.text.tiers[args.liquipediatier]) -- Stores as X-tier, not the integer

	-- Wiki specific vars
	Variables.varDefine('raw_sdate', args.sdate or args.date)
	Variables.varDefine('raw_edate', args.edate or args.date)
	Variables.varDefine('tournament_valve_major',
		(args.valvetier or ''):lower() == _TIER_VALVE_MAJOR and 'true' or args.valvemajor)
	Variables.varDefine('tournament_valve_tier',
		mw.getContentLanguage():ucfirst((args.valvetier or ''):lower()))
	Variables.varDefine('tournament_cstrike_major', args.cstrikemajor)

	Variables.varDefine('tournament_mode',
		(String.isNotEmpty(args.individual) or String.isNotEmpty(args.player_number))
		and _MODE_1v1 or _MODE_TEAM
	)
	Variables.varDefine('no team result',
		(args.series == 'ESEA Rank S' or
		args.series == 'FACEIT Pro League' or
		args.series == 'Danish Pro League' or
		args.series == 'Swedish Pro League') and 'true' or 'false')

end

function CustomLeague:addToLpdb(lpdbData, args)
	if Logic.readBool(args.charity) or Logic.readBool(args.noprize) then
		lpdbData.prizepool = 0
	end

	lpdbData.publishertier = args.valvetier
	lpdbData.maps = table.concat(League:getAllArgsForBase(args, 'map'), ';')
	lpdbData.participantsnumber = args.team_number or args.player_number
	lpdbData.sortdate = args.sort_date or lpdbData.enddate
	lpdbData.extradata = {
		prizepoollocal = Variables.varDefault('prizepoollocal', ''),
		startdate_raw = Variables.varDefault('raw_sdate', ''),
		enddate_raw = Variables.varDefault('raw_edate', ''),
		series2 = args.series2,
	}

	return lpdbData
end

function CustomLeague:_createGameCell(args)
	if String.isEmpty(args.game) and String.isEmpty(args.patch) then
		return nil
	end

	local content = ''

	local gameData = CustomLeague.getGame()
	if gameData then
		content = content .. Page.makeInternalLink({}, gameData.name, gameData.link)
	end

	if String.isEmpty(args.epatch) and String.isNotEmpty(args.patch) then
		content = content .. '[[' .. args.patch .. ']]'
	elseif String.isNotEmpty(args.epatch) then
		content = content .. '<br> [[' .. args.patch .. ']]' .. '&ndash;' .. '[[' .. args.epatch .. ']]'
	end

	return content
end

function CustomLeague.getGame()
	return _args.game and GAMES[_args.game] or nil
end

function CustomLeague:_createEslProTierCell(eslProTier)
	if String.isEmpty(eslProTier) then
		return nil
	end

	local tierData = ESL_PRO_TIERS[eslProTier:lower()]

	if tierData then
		return '[[File:'.. tierData.icon ..'|' .. ESL_PRO_TIERS_SIZE .. '|link=' .. tierData.link ..
				'|' .. tierData.name .. ']] ' .. tierData.name
	end
end

function CustomLeague:_createValveTierCell(valveTier)
	if String.isEmpty(valveTier) then
		return nil
	end

	local tierData = VALVE_TIERS[valveTier:lower()]
	if tierData then
		Variables.varDefine('metadesc-valve', tierData.meta)
		return '[[' .. tierData.link .. '|' .. tierData.name .. ']]'
	end

end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
