---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Chronology = Widgets.Chronology
local Center = Widgets.Center

local BASE_CURRENCY = 'USD'
local CURRENCY_DISPLAY_PRECISION = 0
local CURRENCY_VARIABLE_PRECISION = 2
local DEFAULT_TYPE = 'offline'
local MANUAL_SERIES_ICON = 1
local UNKNOWN_DATE_PART = '??'

--- @class SmashLeagueInfobox: InfoboxLeague
--- @field _base InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

--- @param frame Frame
--- @return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	local args = league.args

	-- Abbreviations
	args.circuitabbr = args.abbreviation or CustomLeague.getAbbrFromSeries(args.circuit)
	args.circuit2abbr = args.abbreviation or CustomLeague.getAbbrFromSeries(args.circuit2)

	-- Auto Icon
	local seriesIconLight, seriesIconDark = CustomLeague.getIconFromSeries(args.series)
	args.circuitIconLight, args.circuitIconDark = CustomLeague.getIconFromSeries(args.circuit)
	args.circuitIconLight2, args.circuitIconDark2 = CustomLeague.getIconFromSeries(args.circuit2)
	args.icon = args.icon or seriesIconLight or args.circuitIconLight or args.circuitIconLight2
	args.icondark = args.icondark or seriesIconDark or args.circuitIconDark or args.circuitIconDark2
	args.display_series_icon_from_manual_input = MANUAL_SERIES_ICON

	-- Normalize name
	if not args.overview then
		args.game = Game.toIdentifier{game = args.game}
	end
	-- Default type should be offline unless otherwise specified
	args.type = args.type or DEFAULT_TYPE

	-- Clean numeric inputs
	args.prizepool = CustomLeague._cleanNumericInput(args.prizepool)
	args.doublesprizepool = CustomLeague._cleanNumericInput(args.doublesprizepool)
	args.player_number = CustomLeague._cleanNumericInput(args.player_number)
	args.doubles_number = CustomLeague._cleanNumericInput(args.doubles_number)
	args.singlesfee = CustomLeague._cleanNumericInput(args.singlesfee)
	args.singlesbonus = CustomLeague._cleanNumericInput(args.singlesbonus)
	args.doublesfee = CustomLeague._cleanNumericInput(args.doublesfee)
	args.doublesbonus = CustomLeague._cleanNumericInput(args.doublesbonus)

	-- Implicit prizepools
	args.assumedprizepool = false
	if not args.prizepool and not args.prizepoolusd then
		local prizeMoney = CustomLeague._assumedPrize(args.singlesfee, args.player_number, args.singlesbonus)
		if prizeMoney > 0 then
			args.assumedprizepool = true
			args.prizepool = tostring(prizeMoney)
		end
	end

	if not args.doublesprizepool and not args.doublesprizepoolusd then
		local prizeMoney = CustomLeague._assumedPrize(args.doublesfee, args.doubles_number, args.doublesbonus)
		if prizeMoney > 0 then
			args.assumedprizepool = true
			args.doublesprizepool = tostring(prizeMoney)
		end
	end

	-- Swap prizepool to prizepoolusd when no currency
	if not args.localcurrency or args.localcurrency:upper() == BASE_CURRENCY then
		-- Singles
		args.prizepoolusd = args.prizepoolusd or args.prizepool
		args.prizepool = nil

		-- Doubles
		args.doublesprizepoolusd = args.doublesprizepoolusd or args.doublesprizepool
		args.doublesprizepool = nil
	elseif args.doublesprizepool and args.localcurrency then
		args.doublesprizepoolusd = CustomLeague:_currencyConversion(CustomLeague._cleanNumericInput(args.doublesprizepool),
			args.localcurrency, League:_cleanDate(args.edate) or League:_cleanDate(args.date))
	end

	-- Currency rounding options
	args.currencyDispPrecision = CURRENCY_DISPLAY_PRECISION
	args.currencyVarPrecision = CURRENCY_VARIABLE_PRECISION

	return league:createInfobox()
end

--- @param args table
--- @return string?
function CustomLeague:createLiquipediaTierDisplay(args)
	-- Remove tier display for overview pages
	if args.overview then
		return nil
	end

	return self._base.createLiquipediaTierDisplay(self, args)
end

--- @param args table
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

	if args.doublesprizepool or args.doublesprizepoolusd then
		local doubleArgs = Table.copy(args)
		doubleArgs.setvariables = false
		doubleArgs.prizepool, doubleArgs.prizepoolusd = args.doublesprizepool, args.doublesprizepoolusd
		self.doublePrizepoolDisplay = self:_parsePrizePool(doubleArgs, self.data.endDate)
	end
end

--- @param id string
--- @param widgets Widget[]
--- @return Widget[]
function CustomInjector:parse(id, widgets)
	local league = self.caller
	local args = league.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Number of Players', content = {args.player_number}},
			Cell{name = 'Doubles Players', content = {args.doubles_number}},
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

		local singles = Array.map(league:getAllArgsForBase(args, 's_stage'), CustomLeague._createNoWrappingSpan)
		if #singles > 0 then
			table.insert(widgets, Title{children = 'Singles Stages'})
			table.insert(widgets, Center{children = {table.concat(singles, '&nbsp;• ')}})
		end

		local doubles = Array.map(league:getAllArgsForBase(args, 'd_stage'), CustomLeague._createNoWrappingSpan)
		if #doubles > 0 then
			table.insert(widgets, Title{children = 'Doubles Stages'})
			table.insert(widgets, Center{children = {table.concat(doubles, '&nbsp;• ')}})
		end
	elseif id == 'dates' then
		return {
			Cell{name = 'Date', content = {
				args.date and CustomLeague:_formatDate(args.date)
			}},
			Cell{name = 'Start Date', content = {
				args.sdate and CustomLeague:_formatDate(args.sdate)
			}},
			Cell{name = 'End Date', content = {
				args.edate and CustomLeague:_formatDate(args.edate)
			}},
		}
	elseif id == 'prizepool' then
		widgets = {}

		-- Normal prize pool
		if args.prizepool or args.prizepoolusd then
			table.insert(widgets, Cell{name = 'Prize pool', content = {league.prizepoolDisplay}})
		end

		-- Doubles prize pool
		if args.doublesprizepool or args.doublesprizepoolusd then
			table.insert(widgets,Cell{name = 'Doubles prize pool', content = {league.doublePrizepoolDisplay}})
		end
	elseif id == 'gamesettings' then
		if not args.overview then
			local version = {args.version, args.endversion}
			return {
				Cell{name = 'Game', content = {Game.name{game = args.game}}},
				Cell{name = 'Version', content = {table.concat(version, '&nbsp;- ')}},
			}
		end
	elseif id == 'format' then
		table.insert(widgets, Cell{name = 'Doubles Format', content = {args.doubles_format}})
	end

	return widgets
end

--- @param lpdbData table
--- @param args table
--- @return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = string.gsub(args.player_number or '', ',', '')

	if Logic.readBool(args.overview) then
		lpdbData.game = 'none'
		lpdbData.liquipediatier = -99
	end

	-- Temporary backwards compatability for location
	lpdbData.location = args.country
	lpdbData.location2 = args.city

	lpdbData.extradata.assumedprizepool = tostring(args.assumedprizepool or '')
	lpdbData.extradata.doubles_prizepool = tostring(args.doublesprizepoolusd)
	lpdbData.extradata.circuit = args.circuit
	lpdbData.extradata.circuit2 = args.circuit2
	lpdbData.extradata.circuit_tier = args.circuittier
	lpdbData.extradata.circuit2_tier = args.circuit2tier

	Variables.varDefine('tournament_extradata', Json.stringify(lpdbData.extradata))

	return lpdbData
end

--- @param args table
function CustomLeague:defineCustomPageVariables(args)
	-- Custom vars
	Variables.varDefine('assumedprizepool', tostring(args.assumedprizepool))
	if args.assumedprizepool then
		Variables.varDefine('assumedprizepoolusd', args.prizepoolusd)
	end
	Variables.varDefine('circuit', args.circuit)
	Variables.varDefine('circuittier', args.circuittier)
	Variables.varDefine('circuitabbr', args.circuitabbr)
	Variables.varDefine('circuit2', args.circuit2)
	Variables.varDefine('circuit2tier', args.circuit2tier)
	Variables.varDefine('seriesabbr', args.abbreviation)
	Variables.varDefine('tournament_link', self.pagename)
	Variables.varDefine('doubles_entrants', args.doubles_number)
	Variables.varDefine('doublesprizepool', args.doublesprizepool)
	Variables.varDefine('doublesprizepoolusd', args.doublesprizepoolusd)
	Variables.varDefine('notranked', args.notranked)

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

--- @param args table
--- @return string[]
function CustomLeague:getWikiCategories(args)
	local categories = {}

	if args.game then
		table.insert(categories, Game.name{game = args.game} .. ' Competitions')
	end

	if args.notranked then
		table.insert(categories, 'Unranked Tournaments')
	end

	return categories
end

--- @param page string?
--- @param query string
--- @return series?
function CustomLeague._querySeries(page, query)
	if not page then
		return
	end

	local sourcePagename = string.gsub(mw.ext.TeamLiquidIntegration.resolve_redirect(page), ' ', '_')

	return mw.ext.LiquipediaDB.lpdb('series', {
		conditions = '[[pagename::' .. sourcePagename .. ']]',
		query = query,
		limit = 1,
	})[1]
end

--- @param page string?
--- @return string?
function CustomLeague.getAbbrFromSeries(page)
	local series = CustomLeague._querySeries(page, 'abbreviation')
	return series and series.abbreviation or nil
end

--- @param page string?
--- @return string?
--- @return string?
function CustomLeague.getIconFromSeries(page)
	local series = CustomLeague._querySeries(page, 'icon, icondark')
	if not series then
		return
	end
	return series.icon, series.icondark
end

--- @param content Html|string|number|nil
--- @return string
function CustomLeague._createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return tostring(span)
end

---@param fee string|number|nil
---@param participants string|number|nil
---@param bonus string|number|nil
---@return number
function CustomLeague._assumedPrize(fee, participants, bonus)
	participants = tonumber(participants) or 0
	fee = tonumber(fee) or 0
	bonus = tonumber(bonus) or 0

	return fee * participants + bonus
end

---@param localPrize string|number|nil
---@param currency string
---@param exchangeDate string?
---@return number?
function CustomLeague:_currencyConversion(localPrize, currency, exchangeDate)
	local currencyRate = Currency.getExchangeRate{
		currency = currency,
		date = exchangeDate,
		setVariables = true,
	}
	if not currencyRate then
		return
	end

	return currencyRate * localPrize
end

--- Removes commas from a string
---@param value string?
---@return string?
function CustomLeague._cleanNumericInput(value)
	if Logic.isEmpty(value) then
		return nil
	end
	---@cast value -nil

	return (string.gsub(value, ',', ''))
end

--- @param widgets Widget[]
--- @param circuitIndex string|number?
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

--- @param circuitIndex string|number
--- @return string?
function CustomLeague:_createCircuitLink(circuitIndex)
	local args = self.args

	return self:createSeriesDisplay({
		displayManualIcons = true,
		series = args['circuit' .. circuitIndex],
		abbreviation = args['circuit' .. circuitIndex .. 'abbr'],
	}, self.data['circuitIconDisplay' .. circuitIndex])
end

---@param date string
---@return string
function CustomLeague:_formatDate(date)
	-- Assume there are three date parts, and assume the year is known
	local dateParts = mw.text.split(date, '-', true)

	-- Only year is known
	if dateParts[2] == UNKNOWN_DATE_PART and dateParts[3] == UNKNOWN_DATE_PART then
		return dateParts[1]

		-- Month and year are known
	elseif dateParts[3] == UNKNOWN_DATE_PART then
		return mw.getContentLanguage():formatDate('F Y', dateParts[1] .. '-' .. dateParts[2] .. '-01')

		-- All parts known
	else
		return mw.getContentLanguage():formatDate('F j, Y', date)
	end
end

return CustomLeague
