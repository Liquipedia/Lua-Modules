---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local Namespace = require('Module:Namespace')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Currency = Lua.import('Module:Currency', {requireDevIfEnabled = true})
local Game = Lua.import('Module:Game', {requireDevIfEnabled = true})
local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner', {requireDevIfEnabled = true})
local Tier = Lua.import('Module:Tier/Custom', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

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

local RESTRICTIONS = {
	['female'] = {
		name = 'Female Players Only',
		link = 'Female Tournaments',
		data = 'female',
	},
	['academy'] = {
		name = 'Academy Teams Only',
		link = 'Academy Tournaments',
		data = 'academy',
	}
}

local _DATE_TBA = 'tba'

local _MODE_1v1 = '1v1'
local _MODE_TEAM = 'team'

local PRIZE_POOL_ROUND_PRECISION = 2

local _args

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	_args.publisherdescription = 'metadesc-valve'
	_args.liquipediatier = Tier.toNumber(_args.liquipediatier)
	_args.currencyDispPrecision = PRIZE_POOL_ROUND_PRECISION
	_args.gameData = Game.raw{game = _args.game, useDefault = false}

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay
	league.shouldStore = CustomLeague.shouldStore

	return league:createInfobox()
end

function CustomLeague:shouldStore(args)
	return Namespace.isMain() and not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
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
	table.insert(widgets, Cell{
			name = 'Restrictions',
			content = CustomLeague.createRestrictionsCell(_args.restrictions)
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

	if Table.isNotEmpty(args.gameData) then
		table.insert(categories, (args.gameData.abbreviation or args.gameData.name) .. ' Tournaments')
	else
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

	if String.isEmpty(args.country) then
		table.insert(categories, 'Tournaments without location')
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

	if String.isNotEmpty(args.restrictions) then
		Array.extendWith(categories, Array.map(CustomLeague.getRestrictions(args.restrictions),
				function(res) return res.link end))
	end

	return categories
end

function CustomLeague:appendLiquipediatierDisplay(args)
	if Logic.readBool(args.cstrikemajor) then
		return ' [[File:cstrike-icon.png|x16px|link=Counter-Strike Majors|Counter-Strike Major]]'
	end
	return ''
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
	local tierName = Tier.toName(args.liquipediatier)
	Variables.varDefine('tournament_tier', tierName) -- Stores as X-tier, not the integer

	-- Wiki specific vars
	local valveTier = mw.getContentLanguage():ucfirst((args.valvetier or ''):lower())
	Variables.varDefine('tournament_valve_tier', valveTier)
	Variables.varDefine('tournament_publishertier', valveTier)
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

	-- Prize Pool vars
	if String.isNotEmpty(args.localcurrency) and String.isNotEmpty(args.prizepool) then
		local currency = string.upper(args.localcurrency)
		local prize = InfoboxPrizePool._cleanValue(args.prizepool)
		Variables.varDefine('prizepoollocal', Currency.display(currency, prize, {
					formatValue = true,
					formatPrecision = PRIZE_POOL_ROUND_PRECISION
				}))
	end
end

function CustomLeague:addToLpdb(lpdbData, args)
	if Logic.readBool(args.charity) or Logic.readBool(args.noprize) then
		lpdbData.prizepool = 0
	end

	lpdbData.maps = table.concat(League:getAllArgsForBase(args, 'map'), ';')
	lpdbData.sortdate = args.sort_date or lpdbData.enddate

	lpdbData.extradata.prizepoollocal = Variables.varDefault('prizepoollocal')
	lpdbData.extradata.startdate_raw = args.sdate or args.date
	lpdbData.extradata.enddate_raw = args.edate or args.date
	lpdbData.extradata.shortname2 = args.shortname2

	Array.forEach(CustomLeague.getRestrictions(args.restrictions),
		function(res) lpdbData.extradata['restriction_' .. res.data] = 1 end)

	-- Extradata variable
	Variables.varDefine('tournament_extradata', Json.stringify(lpdbData.extradata))

	return lpdbData
end

function CustomLeague:_createGameCell(args)
	if Table.isEmpty(args.gameData) and String.isEmpty(args.patch) then
		return nil
	end

	local content = ''

	if Table.isNotEmpty(args.gameData) then
		content = content .. Page.makeInternalLink({}, args.gameData.name, args.gameData.link)
	end

	if String.isEmpty(args.epatch) and String.isNotEmpty(args.patch) then
		content = content .. '[[' .. args.patch .. ']]'
	elseif String.isNotEmpty(args.epatch) then
		content = content .. '<br> [[' .. args.patch .. ']]' .. '&ndash;' .. '[[' .. args.epatch .. ']]'
	end

	return content
end

function CustomLeague.getRestrictions(restrictions)
	if String.isEmpty(restrictions) then
		return {}
	end

	return Array.map(mw.text.split(restrictions, ','),
		function(restriction) return RESTRICTIONS[mw.text.trim(restriction)] end)
end

function CustomLeague.createRestrictionsCell(restrictions)
	local restrictionData = CustomLeague.getRestrictions(restrictions)
	if #restrictionData == 0 then
		return {}
	end

	return Array.map(restrictionData, function(res) return League:createLink(res.link, res.name) end)
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
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

return CustomLeague
