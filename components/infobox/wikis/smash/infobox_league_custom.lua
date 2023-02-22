---
-- @Liquipedia
-- wiki=smash
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})
local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Chronology = Widgets.Chronology
local Center = Widgets.Center

local _args
local _league

local BASE_CURRENCY = 'USD'

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = _league.args

	-- Abbreviations
	_args.circuitabbr = _args.abbreviation or CustomLeague.getAbbrFromSeries(_args.circuit)
	_args.circuit2abbr = _args.abbreviation or CustomLeague.getAbbrFromSeries(_args.circuit2)

	-- Auto Icon
	local seriesIconLight, seriesIconDark = CustomLeague.getIconFromSeries(_args.series)
	_args.icon = _args.icon or seriesIconLight
	_args.icondark = _args.icondark or seriesIconDark

	-- Normalize name
	_args.game = Game.name{game = _args.game}

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

	-- Swap prizepool to prizepoolusd when no currency
	if not _args.localcurrency or _args.localcurrency:upper() == BASE_CURRENCY then
		_args.prizepoolusd = _args.prizepoolusd or _args.prizepool
		_args.prizepool = nil
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
	table.insert(widgets, Cell{name = 'Doubles Players', content = {_args.doubles_number}})
	table.insert(widgets, Cell{name = 'Number of Teams', content = {_args.team_number}})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then
		if _args.circuit or _args.points or _args.circuit_next or _args.circuit_previous then
			table.insert(widgets, Title{name = 'Circuit Information'})
			table.insert(widgets, Cell{name = 'Circuit', content = {_args.circuit}})
			table.insert(widgets, Cell{name = 'Circuit Tier', content = {
				_args.circuittier and (_args.circuittier .. ' Tier') or nil}
			})
			table.insert(widgets, Cell{name = 'Tournament Region', content = {_args.region}})
			table.insert(widgets, Cell{name = 'Points', content = {_args.points}})
			table.insert(widgets, Chronology{content = {next = _args.circuit_next, previous = _args.circuit_previous}})
		end

		if _args.circuit2 or _args.points2 or _args.circuit2_next or _args.circuit2_previous then
			table.insert(widgets, Title{name = 'Circuit Information'})
			table.insert(widgets, Cell{name = 'Circuit', content = {_args.circuit2}})
			table.insert(widgets, Cell{name = 'Circuit Tier', content = {
				_args.circuittier2 and (_args.circuittier2 .. ' Tier') or nil}
			})
			table.insert(widgets, Cell{name = 'Tournament Region', content = {_args.region}})
			table.insert(widgets, Cell{name = 'Points', content = {_args.points2}})
			table.insert(widgets, Chronology{content = {next = _args.circuit2_next, previous = _args.circuit2_previous}})
		end

		local singles = Array.map(_league:getAllArgsForBase(_args, 's_stage'), CustomLeague._createNoWrappingSpan)
		if #singles > 0 then
			table.insert(widgets, Title{name = 'Singles Stages'})
			table.insert(widgets, Center{content = table.concat(singles, '&nbsp;• ')})
		end

		local doubles = Array.map(_league:getAllArgsForBase(_args, 'd_stage'), CustomLeague._createNoWrappingSpan)
		if #doubles > 0 then
			table.insert(widgets, Title{name = 'Doubles Stages'})
			table.insert(widgets, Center{content = table.concat(doubles, '&nbsp;• ')})
		end

	elseif id == 'prizepool' then
		if _args.prizepoolassumed then
			widgets[1].content[1] = Abbreviation.make(
				widgets[1].content[1],
				'This prize is assumed, and has not been confirmed'
			)
		end

		local prizePool, prizePoolUsd = _args.doublesprizepool, _args.doublesprizepoolusd
		if not prizePool and not prizePoolUsd then
			_args.prizepoolassumed = true

			local singlesFee = tonumber(_args.doublesfee) or 0
			local playerNumber = tonumber(_args.doubles_number) or 0
			local singlesBonus = tonumber(_args.doublesbonus) or 0
		end
		table.insert(widgets, Cell{name = 'Doubles prize pool', content = {
			InfoboxPrizePool.display{
				prizepool = _args.prizepool,
				prizepoolusd = _args.prizepoolusd,
				currency = _args.localcurrency,
				rate = _args.currency_rate,
				date = Variables.varDefault('tournament_enddate'),
			}
		}})

	elseif id == 'gamesettings' then
		local version = {_args.version, _args.endversion}
		return {
			Cell{name = 'Game', content = {_args.game}},
			Cell{name = 'Version', content = {table.concat(version, '&nbsp;- ')}},
		}

	elseif id == 'format' then
		table.insert(widgets, Cell{name = 'Doubles Format', content = {_args.doubles_format}})
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = string.gsub(_args.player_number or '', ',', '')

	if Logic.readBool(_args.overview) then
		lpdbData.game = 'none'
	end

	lpdbData.extradata.assumedprizepool = tostring(_args.prizepoolassumed)
	lpdbData.extradata.circuit = _args.circuit
	lpdbData.extradata.circuit_tier = _args.circuit_tier

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	-- Custom vars
	Variables.varDefine('assumedpayout', tostring(_args.prizepoolassumed))
	Variables.varDefine('tournament_circuit', _args.circuit)
	Variables.varDefine('circuittier', _args.circuittier)
	Variables.varDefine('circuitabbr', _args.circuitabbr)
	Variables.varDefine('seriesabbr', _args.abbreviation)
	Variables.varDefine('tournament_link', self.pagename)

	-- Legacy vars
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')
	Variables.varDefine('prizepoolusd', Variables.varDefault('tournament_prizepoolusd'))
	Variables.varDefine('tournament_entrants', string.gsub(_args.player_number or '', ',', ''))
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

	if _args.game then
		table.insert(categories, _args.game .. ' Competitions')
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

function CustomLeague._createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

function CustomLeague._calculateAssumedPrize(fee, participants, bonus)
	fee = tonumber(fee) or 0
	participants = tonumber(participants) or 0
	bonus = tonumber(bonus) or 0

	return fee * participants + bonus
end

return CustomLeague
