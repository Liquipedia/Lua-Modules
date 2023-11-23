---
-- @Liquipedia
-- wiki=fighters
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})
local LeagueIcon = Lua.import('Module:LeagueIcon', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Chronology = Widgets.Chronology

local _args
local _league

local ABBR_USD = '<abbr title="United States Dollar">USD</abbr>'
local DEFAULT_TYPE = 'offline'
local MANUAL_SERIES_ICON = true
local TODAY = os.date('%Y-%m-%d', os.time())

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	-- Abbreviations
	_args.circuitabbr = _args.circuitabbr or CustomLeague.getAbbrFromSeries(_args.circuit)

	-- Auto Icon
	local seriesIconLight, seriesIconDark = CustomLeague.getIconFromSeries(_args.series)
	_args.circuitIconLight, _args.circuitIconDark = CustomLeague.getIconFromSeries(_args.circuit)
	_args.icon = _args.icon or seriesIconLight or _args.circuitIconLight
	_args.icondark = _args.icondark or seriesIconDark or _args.circuitIconDark
	_args.display_series_icon_from_manual_input = MANUAL_SERIES_ICON

	-- Normalize name
	_args.game = Game.toIdentifier{game = _args.game}
	-- Default type should be offline unless otherwise specified
	_args.type = _args.type or DEFAULT_TYPE

	-- Implicit prizepools
	_args.prizepoolassumed = false
	if not _args.prizepool and not _args.prizepoolusd then
		_args.prizepoolassumed = true

		local singlesFee = tonumber(_args.singlesfee) or 0
		local playerNumber = tonumber(_args.player_number) or 0
		local singlesBonus = tonumber(_args.singlesbonus) or 0

		local prizeMoney = singlesFee * playerNumber + singlesBonus
		if prizeMoney > 0 then
			_args.prizepool = prizeMoney
		end
	end

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{name = 'Number of Players', content = {_args.player_number}})
	table.insert(widgets, Cell{name = 'Number of Teams', content = {_args.team_number}})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then
		if _args.circuit or _args.points or _args.circuit_next or _args.circuit_previous then
			table.insert(widgets, Title{name = 'Circuit Information'})
			CustomLeague:_createCircuitInformation(widgets)
		end
		if _args.circuit2 or _args.points2 or _args.circuit2_next or _args.circuit2_previous then
			CustomLeague:_createCircuitInformation(widgets, '2')
		end

	elseif id == 'prizepool' then
		return {
			Cell{name = 'Prize pool', content = {CustomLeague:_createPrizepool()}}
		}

	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game', content = {Page.makeInternalLink(
				{onlyIfExists = true},
				Game.name{game = _args.game},
				Game.link{game = _args.game}
			) or Game.name{game = _args.game}}},
			Cell{name = 'Version', content = {_args.version}},
		}
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = string.gsub(args.player_number or '', ',', '')

	if Logic.readBool(args.overview) then
		lpdbData.game = 'none'
	end

	lpdbData.extradata.assumedprizepool = tostring(args.prizepoolassumed)
	lpdbData.extradata.circuit = args.circuit
	lpdbData.extradata.circuittier = args.circuittier
	lpdbData.extradata.circuit2 = args.circuit2
	lpdbData.extradata.circuit2tier = args.circuit2tier

	return lpdbData
end

function CustomLeague:defineCustomPageVariables(args)
	-- Custom vars
	Variables.varDefine('assumedpayout', tostring(args.prizepoolassumed))
	Variables.varDefine('circuit', args.circuit)
	Variables.varDefine('circuittier', args.circuittier)
	Variables.varDefine('circuitabbr', args.circuitabbr)
	Variables.varDefine('circuit2', args.circuit2)
	Variables.varDefine('circuit2tier', args.circuit2tier)
	Variables.varDefine('circuit2abbr', args.circuit2abbr)
	Variables.varDefine('seriesabbr', args.abbreviation)
	Variables.varDefine('tournament_link', self.pagename)

	-- Legacy vars
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('prizepoolusd', Variables.varDefault('tournament_prizepoolusd'))
	Variables.varDefine('tournament_entrants', string.gsub(args.player_number or '', ',', ''))
	Variables.varDefine('localcurrency', Variables.varDefault('tournament_currency', ''):upper())

	-- Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('formatted_tournament_date', sdate)
	Variables.varDefine('date', edate)
	Variables.varDefine('sdate', sdate)
	Variables.varDefine('edate', edate)
end

function CustomLeague:getWikiCategories(args)
	local categories = {}

	if args.game then
		table.insert(categories, Game.name{game = args.game} .. ' Competitions')
	end

	return categories
end

function CustomLeague._querySeries(page, query)
	if not page then
		return
	end

	local sourcePagename = string.gsub(mw.ext.TeamLiquidIntegration.resolve_redirect(page), ' ', '_')

	local data = mw.ext.LiquipediaDB.lpdb('series', {
		conditions = '[[pagename::' .. sourcePagename .. ']]',
		query = query,
		limit = 1,
	})

	if not data or not data[1] then
		return
	end

	return data[1]
end

function CustomLeague.getAbbrFromSeries(page)
	local series = CustomLeague._querySeries(page, 'abbreviation')
	return series and series.abbreviation or nil
end

function CustomLeague.getIconFromSeries(page)
	local series = CustomLeague._querySeries(page, 'icon, icondark')
	if not series then
		return
	end

	return series.icon, series.icondark
end

function CustomLeague:_createPrizepool()
	if Logic.isEmpty(_args.prizepool) and
		Logic.isEmpty(_args.prizepoolusd) then
		return nil
	end

	local localCurrency = _args.localcurrency
	local prizePoolUSD = _args.prizepoolusd
	local prizePool = _args.prizepool --[[@as number|string|nil]]

	local display
	if prizePoolUSD then
		prizePoolUSD = CustomLeague:_cleanPrizeValue(prizePoolUSD)
	end

	prizePool = CustomLeague:_cleanPrizeValue(prizePool, localCurrency)

	if not prizePoolUSD and localCurrency then
		local exchangeDate = Variables.varDefault('tournament_enddate', TODAY)
		prizePoolUSD = CustomLeague:_currencyConversion(prizePool, localCurrency:upper(), exchangeDate)
		if not prizePoolUSD then
			error('Invalid local currency "' .. localCurrency .. '"')
		end
	end

	if prizePoolUSD and prizePool then
		display = Currency.display((localCurrency or ''):lower(), Currency.formatMoney(prizePool, 2))
		.. '<br>(≃ $' .. Currency.formatMoney(prizePoolUSD, 2) .. ' ' .. ABBR_USD .. ')'
	elseif prizePool or prizePoolUSD then
		display = '$' .. Currency.formatMoney(prizePool or prizePoolUSD, 2) .. ' ' .. ABBR_USD
	end

	Variables.varDefine('usd prize', prizePoolUSD or prizePool)
	Variables.varDefine('tournament_prizepoolusd', prizePoolUSD or prizePool)
	Variables.varDefine('local prize', prizePool)

	if _args.prizepoolassumed then
		display = Abbreviation.make(
			display,
			'This prize is assumed, and has not been confirmed'
		)
	end

	return display
end

function CustomLeague:_currencyConversion(localPrize, currency, exchangeDate)
	local usdPrize
	local currencyRate = Currency.getExchangeRate{
		currency = currency,
		date = exchangeDate,
		setVariables = true,
	}
	if currencyRate then
		usdPrize = currencyRate * localPrize
	end

	return usdPrize
end

function CustomLeague:_cleanPrizeValue(value, currency)
	if String.isEmpty(value) then
		return nil
	end

	--remove white spaces, '&nbsp;' and ','
	value = string.gsub(value, '%s', '')
	value = string.gsub(value, '&nbsp;', '')
	value = string.gsub(value, ',', '')
	value = string.gsub(value, '%$', '')

	return value
end

function CustomLeague:_createCircuitInformation(widgets, circuitIndex)
	circuitIndex = circuitIndex or ''
	local circuitArgs = {
		circuit = _args['circuit' .. circuitIndex],
		abbreviation = _args['circuit' .. circuitIndex .. 'abbr'],
		icon = _args['circuit' .. circuitIndex .. 'IconLight'],
		iconDark = _args['circuit' .. circuitIndex .. 'IconDark'],
		tier = _args['circuit' .. circuitIndex .. 'tier'],
		region = _args['region' .. circuitIndex],
		points = _args['points' .. circuitIndex],
		next = _args['circuit' .. circuitIndex .. '_next'],
		previous = _args['circuit' .. circuitIndex .. '_previous'],
	}

	table.insert(
		widgets,
		Cell{
			name = 'Circuit',
			content = {
				CustomLeague:_createCircuitLink(
					circuitArgs.circuit,
					circuitArgs.abbreviation,
					circuitArgs.icon,
					circuitArgs.iconDark or circuitArgs.icon
				)
			}
		}
	)
	table.insert(widgets, Cell{name = 'Circuit Tier', content = {circuitArgs.tier}})
	table.insert(widgets, Cell{name = 'Tournament Region', content = {circuitArgs.region}})
	table.insert(widgets, Cell{name = 'Points', content = {circuitArgs.points}})
	table.insert(widgets, Chronology{content = {next = circuitArgs.next, previous = circuitArgs.previous}})
end

function CustomLeague:_createCircuitLink(circuit, abbreviation, icon, iconDark)
	if String.isEmpty(circuit) then
		return
	end

	local circuitPageExists = Page.exists(circuit)

	local output = LeagueIcon.display{
		icon = icon,
		iconDark = iconDark,
		series = circuit,
		abbreviation = abbreviation,
		date = Variables.varDefault('tournament_enddate'),
		options = {noLink = not circuitPageExists}
	}
	if output == LeagueIcon.display{} then
		output = ''
	else
		output = output .. ' '
		if not _args.icon then
			League:_setIconVariable(output, icon, iconDark)
		end
	end

	if not circuitPageExists then
		if String.isEmpty(abbreviation) then
			return output .. circuit
		else
			return output .. abbreviation
		end
	elseif String.isEmpty(abbreviation) then
		return output .. '[[' .. circuit .. ']]'
	end
	return output .. '[[' .. circuit .. '|' .. abbreviation .. ']]'
end

return CustomLeague
