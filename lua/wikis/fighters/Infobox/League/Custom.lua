---
-- @Liquipedia
-- wiki=fighters
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Chronology = Widgets.Chronology

local ABBR_USD = '<abbr title="United States Dollar">USD</abbr>'
local DEFAULT_TYPE = 'offline'
local MANUAL_SERIES_ICON = true
local TODAY = os.date('%Y-%m-%d', os.time())

---@class FightersLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	local args = league.args

	-- Abbreviations
	args.circuitabbr = args.circuitabbr or CustomLeague.getAbbrFromSeries(args.circuit)

	-- Auto Icon
	local seriesIconLight, seriesIconDark = CustomLeague.getIconFromSeries(args.series)
	args.circuitIconLight, args.circuitIconDark = CustomLeague.getIconFromSeries(args.circuit)
	args.icon = args.icon or seriesIconLight or args.circuitIconLight
	args.icondark = args.icondark or seriesIconDark or args.circuitIconDark
	args.display_series_icon_from_manual_input = MANUAL_SERIES_ICON

	-- Normalize name
	args.game = Game.toIdentifier{game = args.game}
	-- Default type should be offline unless otherwise specified
	args.type = args.type or DEFAULT_TYPE

	-- Implicit prizepools
	args.prizepoolassumed = false
	if not args.prizepool and not args.prizepoolusd then
		args.prizepoolassumed = true

		local singlesFee = tonumber(args.singlesfee) or 0
		local playerNumber = tonumber(args.player_number) or 0
		local singlesBonus = tonumber(args.singlesbonus) or 0

		local prizeMoney = singlesFee * playerNumber + singlesBonus
		if prizeMoney > 0 then
			args.prizepool = prizeMoney
		end
	end

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	Array.forEach({'', 2}, function(circuitIndex)
		local icon, iconDark, display = self:getIcons{
			displayManualIcons = true,
			series = args['circuit' .. circuitIndex],
			abbreviation = args['circuit' .. circuitIndex .. 'abbr'],
			icon = args['circuit' .. circuitIndex .. 'IconLight'],
			iconDark = args['circuit' .. circuitIndex .. 'IconDark'],
		}
		self.data['circuitIconDisplay' .. circuitIndex] = display
		self.data.icon = Logic.emptyOr(self.data.icon, icon)
		self.data.iconDark = Logic.emptyOr(self.data.iconDark, iconDark)
	end)
end

---@param args table
---@param endDate string?
---@return number|string?
function CustomLeague:displayPrizePool(args, endDate)
	local localCurrency = args.localcurrency
	local prizePoolUSD = args.prizepoolusd
	local prizePool = args.prizepool --[[@as number|string|nil]]

	local display
	if prizePoolUSD then
		prizePoolUSD = CustomLeague._cleanPrizeValue(prizePoolUSD)
	end

	prizePool = CustomLeague._cleanPrizeValue(prizePool)

	if not prizePoolUSD and localCurrency then
		local exchangeDate = endDate or TODAY --[[@as string]]
		prizePoolUSD = CustomLeague._currencyConversion(prizePool, localCurrency:upper(), exchangeDate)
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
	Variables.varDefine('tournament_prizepoollocal', prizePool)
	Variables.varDefine('tournament_currency',
		string.upper(Variables.varDefault('tournament_currency', localCurrency) or ''))

	if args.prizepoolassumed then
		display = Abbreviation.make{text = display, title = 'This prize is assumed, and has not been confirmed'}
	end

	return display
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Number of Players', content = {args.player_number}},
			Cell{name = 'Number of Teams', content = {args.team_number}}
		)
	elseif id == 'customcontent' then
		if args.circuit or args.points or args.circuit_next or args.circuit_previous then
			table.insert(widgets, Title{children = 'Circuit Information'})
			self.caller:_createCircuitInformation(widgets)
		end
		if args.circuit2 or args.points2 or args.circuit2_next or args.circuit2_previous then
			self.caller:_createCircuitInformation(widgets, '2')
		end
	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game', content = {Page.makeInternalLink(
				{onlyIfExists = true},
				Game.name{game = args.game},
				Game.link{game = args.game}
			) or Game.name{game = args.game}}},
			Cell{name = 'Version', content = {args.version}},
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = string.gsub(args.player_number or '', ',', '')

	if Logic.readBool(args.overview) then
		lpdbData.game = 'none'
	end

	lpdbData.extradata.assumedprizepool = tostring(args.prizepoolassumed)
	lpdbData.extradata.circuit = args.circuit
	lpdbData.extradata.circuit_tier = args.circuittier
	lpdbData.extradata.circuit2 = args.circuit2
	lpdbData.extradata.circuit2_tier = args.circuit2tier

	Variables.varDefine('tournament_extradata', Json.stringify(lpdbData.extradata))

	return lpdbData
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Custom vars
	Variables.varDefine('assumedpayout', tostring(args.prizepoolassumed))
	Variables.varDefine('circuit', args.circuit)
	Variables.varDefine('circuittier', args.circuittier)
	Variables.varDefine('circuitabbr', args.circuitabbr)
	Variables.varDefine('circuitregion', args.region)
	Variables.varDefine('circuit2', args.circuit2)
	Variables.varDefine('circuit2tier', args.circuit2tier)
	Variables.varDefine('circuit2abbr', args.circuit2abbr)
	Variables.varDefine('circuit2region', args.region2)
	Variables.varDefine('seriesabbr', args.abbreviation)
	Variables.varDefine('tournament_link', self.pagename)

	-- Legacy vars
	Variables.varDefine('tournament_tier', args.liquipediatier or '')
	Variables.varDefine('prizepoolusd', self.data.prizepoolUsd)
	Variables.varDefine('tournament_entrants', string.gsub(args.player_number or '', ',', ''))
	Variables.varDefine('localcurrency', self.data.localCurrency)

	-- Legacy date vars
	Variables.varDefine('tournament_sdate', self.data.startDate)
	Variables.varDefine('tournament_edate', self.data.endDate)
	Variables.varDefine('tournament_date', self.data.endDate)
	Variables.varDefine('formatted_tournament_date', self.data.startDate)
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {
		args.game and (Game.name{game = args.game} .. ' Competitions') or nil,
	}
end

---@param page string?
---@param query string
---@return series?
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

---@param page string?
---@return string?
function CustomLeague.getAbbrFromSeries(page)
	local series = CustomLeague._querySeries(page, 'abbreviation')
	return series and series.abbreviation or nil
end

---@param page string?
---@return string?
---@return string?
function CustomLeague.getIconFromSeries(page)
	local series = CustomLeague._querySeries(page, 'icon, icondark')
	if not series then
		return
	end

	return series.icon, series.icondark
end

---@param localPrize string|number|nil
---@param currency string
---@param exchangeDate string?
---@return number?
function CustomLeague._currencyConversion(localPrize, currency, exchangeDate)
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

---@param value string|number|nil
---@return string?
function CustomLeague._cleanPrizeValue(value)
	if Logic.isEmpty(value) then
		return
	end
	---@cast value -nil

	--remove white spaces, '&nbsp;' and ','
	value = string.gsub(value, '%s', '')
	value = string.gsub(value, '&nbsp;', '')
	value = string.gsub(value, ',', '')
	value = string.gsub(value, '%$', '')

	return value
end

---@param widgets Widget[]
---@param circuitIndex string|number?
function CustomLeague:_createCircuitInformation(widgets, circuitIndex)
	local args = self.args
	circuitIndex = circuitIndex or ''
	local circuitArgs = {
		tier = args['circuit' .. circuitIndex .. 'tier'],
		region = args['region' .. circuitIndex],
		points = args['points' .. circuitIndex],
		next = args['circuit' .. circuitIndex .. '_next'],
		previous = args['circuit' .. circuitIndex .. '_previous'],
	}

	Array.appendWith(widgets,
		Cell{
			name = 'Circuit',
			content = {self:_createCircuitLink(circuitIndex)}
		},
		Cell{name = 'Circuit Tier', content = {circuitArgs.tier}},
		Cell{name = 'Tournament Region', content = {circuitArgs.region}},
		Cell{name = 'Points', content = {circuitArgs.points}},
		Chronology{links = {next = circuitArgs.next, previous = circuitArgs.previous}}
	)
end

---@param circuitIndex string|number
---@return string?
function CustomLeague:_createCircuitLink(circuitIndex)
	local args = self.args

	return self:createSeriesDisplay({
		displayManualIcons = true,
		series = args['circuit' .. circuitIndex],
		abbreviation = args['circuit' .. circuitIndex .. 'abbr'],
	}, self.data['circuitIconDisplay' .. circuitIndex])
end

return CustomLeague
