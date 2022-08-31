---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local LeagueIcon = require('Module:LeagueIcon')
local Currency = require('Module:Currency')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Math = require('Module:Math')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Import = Lua.import('Module:PrizePool/Import', {requireDevIfEnabled = true})
local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local Placement = Lua.import('Module:PrizePool/Placement', {requireDevIfEnabled = true})
local SmwInjector = Lua.import('Module:Smw/Injector', {requireDevIfEnabled = true})
local WidgetInjector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

---Note: This can be overwritten
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
---Note: This can be overwritten
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local WidgetFactory = require('Module:Infobox/Widget/Factory')
local WidgetTable = require('Module:Widget/Table')
local TableRow = require('Module:Widget/Table/Row')
local TableCell = require('Module:Widget/Table/Cell')

--- @class PrizePool
local PrizePool = Class.new(function(self, ...) self:init(...) end)

local tournamentVars = PageVariableNamespace('Tournament')

local TODAY = os.date('%Y-%m-%d')

local LANG = mw.language.getContentLanguage()
local DASH = '&#045;'
local NON_BREAKING_SPACE = '&nbsp;'
local BASE_CURRENCY = 'USD'

local LANG = mw.language.getContentLanguage()
local DASH = '&#045;'
local NON_BREAKING_SPACE = '&nbsp;'
local BASE_CURRENCY = 'USD'

local PRIZE_TYPE_USD = 'USD'
local PRIZE_TYPE_LOCAL_CURRENCY = 'LOCAL_CURRENCY'
local PRIZE_TYPE_QUALIFIES = 'QUALIFIES'
local PRIZE_TYPE_POINTS = 'POINTS'
local PRIZE_TYPE_FREETEXT = 'FREETEXT'

-- Allowed none-numeric score values.
local WALKOVER_SCORE = 'W'
local FORFEIT_SCORE = 'FF'
local SPECIAL_SCORES = {WALKOVER_SCORE, FORFEIT_SCORE , 'L', 'DQ', 'D'}

PrizePool.config = {
	showUSD = {
		default = false
	},
	autoUSD = {
		default = true,
		read = function(args)
			return Logic.readBoolOrNil(args.autousd)
		end
	},
	prizeSummary = {
		default = true,
		read = function(args)
			return Logic.readBoolOrNil(args.prizesummary)
		end
	},
	exchangeInfo = {
		default = true,
		read = function(args)
			return Logic.readBoolOrNil(args.exchangeinfo)
		end
	},
	cutafter = {
		default = 4,
		read = function(args)
			return tonumber(args.cutafter)
		end
	},
	storeSmw = {
		default = true,
		read = function(args)
			return Logic.readBoolOrNil(args.storesmw)
		end
	},
	storeLpdb = {
		default = true,
		read = function(args)
			return Logic.readBoolOrNil(args.storelpdb)
		end
	},
	resolveRedirect = {
		default = false,
		read = function(args)
			return Logic.readBoolOrNil(args.resolveRedirect)
		end
	},
	syncPlayers = {
		default = false,
		read = function(args)
			return Logic.readBoolOrNil(args.syncPlayers)
		end
	},
	currencyRatePerOpponent = {
		default = false,
		read = function(args)
			return Logic.readBoolOrNil(args.currencyrateperopponent)
		end
	},
	currencyRoundPrecision = {
		default = 2,
		read = function(args)
			return tonumber(args.currencyroundprecision)
		end
	},
	lpdbPrefix = {
		default = '',
		read = function(args)
			return args.lpdb_prefix or Variables.varDefault('lpdb_prefix') or Variables.varDefault('smw_prefix')
		end
	},
	abbreviateTbd = {
		default = true,
		read = function(args)
			return Logic.readBoolOrNil(args.abbreviateTbd)
		end
	},
	fillPlaceRange = {
		default = true,
		read = function(args)
			return Logic.readBoolOrNil(args.fillPlaceRange)
		end
	},
	resolveRedirect = {
		default = false,
	},
	syncPlayers = {
		default = false,
		read = function(args)
			return Logic.readBoolOrNil(args.syncPlayers)
		end
	},
	currencyRatePerOpponent = {
		default = false,
		read = function(args)
			return Logic.readBoolOrNil(args.currencyrateperopponent)
		end
	},
	currencyRoundPrecision = {
		default = 2,
		read = function(args)
			return tonumber(args.currencyroundprecision)
		end
	},
	lpdbPrefix = {
		default = '',
		read = function(args)
			return args.lpdb_prefix or Variables.varDefault('lpdb_prefix') or Variables.varDefault('smw_prefix')
		end
	},
}

PrizePool.prizeTypes = {
	[PRIZE_TYPE_USD] = {
		sortOrder = 10,

		headerDisplay = function (data)
			local currencyData = Currency.raw(BASE_CURRENCY)
			local currencyText = currencyData.text.prefix .. currencyData.text.suffix
			return TableCell{content = {{currencyText}}}
		end,

		row = 'usdprize',
		rowParse = function (placement, input, context, index)
			return PrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{content = {{'$', Currency.formatMoney(data, headerData.roundPrecision)}}}
			end
		end,
	},
	[PRIZE_TYPE_LOCAL_CURRENCY] = {
		sortOrder = 20,

		header = 'localcurrency',
		headerParse = function (prizePool, input, context, index)
			local currencyData = Currency.raw(input)
			if not currencyData then
				error(input .. ' could not be parsed as a currency, has it been added to [[Module:Currency/Data]]?')
			end
			local currencyText = currencyData.text.prefix .. currencyData.text.suffix

			local currencyRate = Currency.getExchangeRate{
				currency = currencyData.code,
				currencyRate = Variables.varDefault('exchangerate_' .. currencyData.code),
				date = prizePool.date,
				setVariables = true,
			}

			return {
				currency = currencyData.code, currencyText = currencyText,
				symbol = currencyData.symbol, symbolFirst = not currencyData.isAfter,
				rate = currencyRate or 0, roundPrecision = prizePool.options.currencyRoundPrecision,
			}
		end,
		headerDisplay = function (data)
			return TableCell{content = {{data.currencyText}}}
		end,

		row = 'localprize',
		rowParse = function (placement, input, context, index)
			return PrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				local displayText = {Currency.formatMoney(data, headerData.roundPrecision)}

				if headerData.symbolFirst then
					table.insert(displayText, 1, headerData.symbol)
				else
					table.insert(displayText, headerData.symbol)
				end

				return TableCell{content = {displayText}}
			end
		end,

		convertToUsd = function (headerData, data, date, perOpponent)
			local rate = headerData.rate

			if perOpponent then
				rate = Currency.getExchangeRate{
					currency = headerData.currency,
					date = date,
				} or rate
			end

			return (tonumber(data) or 0) * rate
		end,
	},
	[PRIZE_TYPE_QUALIFIES] = {
		sortOrder = 30,

		header = 'qualifies',
		headerParse = function (prizePool, input, context, index)
			local link = mw.ext.TeamLiquidIntegration.resolve_redirect(input):gsub(' ', '_')
			local data = {link = link}

			-- Automatically retrieve information from the Tournament
			local tournamentData = PrizePool._getTournamentInfo(link)
			if tournamentData then
				data.title = tournamentData.tickername
				data.icon = tournamentData.icon
				data.iconDark = tournamentData.icondark
			end

			-- Manual inputs
			local prefix = 'qualifies' .. index
			data.title = context[prefix .. 'name'] or data.title
			data.icon = data.icon or context[prefix .. 'icon']
			data.iconDark = data.iconDark or context[prefix .. 'icondark']

			return data
		end,
		headerDisplay = function (data)
			return TableCell{content = {'Qualifies To'}}
		end,

		row = 'qualified',
		rowParse = function (placement, input, context, index)
			return Logic.readBool(input)
		end,
		rowDisplay = function (headerData, data)
			if not data then
				return
			end

			local content = {}
			if String.isNotEmpty(headerData.icon) then
				local icon = LeagueIcon.display{
					link = headerData.link, name = headerData.title,
					iconDark = headerData.iconDark, icon = headerData.icon,
				}
				table.insert(content, icon)
				table.insert(content, NON_BREAKING_SPACE)
			end

			if String.isNotEmpty(headerData.title) then
				table.insert(content, '[[' .. headerData.link .. '|' .. headerData.title .. ']]')
			else
				table.insert(content, '[[' .. headerData.link .. ']]')
			end

			return TableCell{content = {content}}
		end,

		mergeDisplayColumns = true,
	},
	[PRIZE_TYPE_POINTS] = {
		sortOrder = 40,

		header = 'points',
		headerParse = function (prizePool, input, context, index)
			local pointsData = Table.copy(mw.loadData('Module:Points/data')[input] or {})
			pointsData.title = pointsData.title or 'Points'

			-- Manual overrides
			local prefix = 'points' .. index
			pointsData.link = context[prefix .. 'link'] or pointsData.link

			return pointsData
		end,
		headerDisplay = function (data)
			local headerDisplay = {}

			if String.isNotEmpty(data.icon) then
				local icon = LeagueIcon.display{
					link = data.link, icon = data.icon, iconDark = data.iconDark, name = data.title
				}
				table.insert(headerDisplay, icon)
				table.insert(headerDisplay, NON_BREAKING_SPACE)
			end

			if String.isNotEmpty(data.title) then
				local text
				if String.isNotEmpty(data.titleLong) then
					text = Abbreviation.make(data.title, data.titleLong)
				elseif String.isNotEmpty(data.title) then
					text = data.title
				end

				if String.isNotEmpty(data.link) then
					text = '[[' .. data.link .. '|' .. text .. ']]'
				end

				table.insert(headerDisplay, text)
			end

			return TableCell{content = {headerDisplay}}
		end,

		row = 'points',
		rowParse = function (placement, input, context, index)
			return PrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{content = {{LANG:formatNum(data)}}}
			end
		end,
	},
	[PRIZE_TYPE_FREETEXT] = {
		sortOrder = 50,

		header = 'freetext',
		headerParse = function (prizePool, input, context, index)
			return {title = input}
		end,
		headerDisplay = function (data)
			return TableCell{content = {{data.title}}}
		end,

		row = 'freetext',
		rowParse = function (placement, input, context, index)
			return input
		end,
		rowDisplay = function (headerData, data)
			if String.isNotEmpty(data) then
				return TableCell{content = {{data}}}
			end
		end,
	}
}



Placement.specialStatuses = {
	DQ = {
		active = function (args)
			return Logic.readBool(args.dq)
		end,
		display = function ()
			return Abbreviation.make('DQ', 'Disqualified')
		end,
		lpdb = 'dq',
	},
	DNF = {
		active = function (args)
			return Logic.readBool(args.dnf)
		end,
		display = function ()
			return Abbreviation.make('DNF', 'Did not finish')
		end,
		lpdb = 'dnf',
	},
	DNP = {
		active = function (args)
			return Logic.readBool(args.dnp)
		end,
		display = function ()
			return Abbreviation.make('DNP', 'Did not participate')
		end,
		lpdb = 'dnp',
	},
	W = {
		active = function (args)
			return Logic.readBool(args.w)
		end,
		display = function ()
			return 'W'
		end,
		lpdb = 1,
	},
	D = {
		active = function (args)
			return Logic.readBool(args.d)
		end,
		display = function ()
			return 'D'
		end,
		lpdb = 1,
	},
	L = {
		active = function (args)
			return Logic.readBool(args.l)
		end,
		display = function ()
			return 'L'
		end,
		lpdb = 2,
	},
}

function PrizePool:init(args)
	self.args = self:_parseArgs(args)

	self.pagename = mw.title.getCurrentTitle().text
	self.date = PrizePool._getTournamentDate()
	self.opponentType = self.args.type
	if self.args.opponentLibrary then
		Opponent = Lua.import('Module:'.. self.args.opponentLibrary, {requireDevIfEnabled = true})
		self.opponentLibrary = Opponent
	end
	if self.args.opponentDisplayLibrary then
		OpponentDisplay = Lua.import('Module:'.. self.args.opponentDisplayLibrary, {requireDevIfEnabled = true})
	end
	if self.args.opponentDisplayLibrary then
		OpponentDisplay = require('Module:'.. self.args.opponentDisplayLibrary)
	end

	self.options = {}
	self.prizes = {}
	self.placements = {}

	self.usedAutoConvertedCurrency = false

	return self
end

function PrizePool:_parseArgs(args)
	local parsedArgs = Table.deepCopy(args)
	local typeStruct = Json.parseIfString(args.type)

	self:assertOpponentStructType(typeStruct)

	parsedArgs.type = typeStruct.type

	return parsedArgs
end

function PrizePool:create()
	self.options = self:_readConfig(self.args)
	self.prizes = self:_readPrizes(self.args)
	self.placements = self:_readPlacements(self.args)
	self.placements = Import.run(self.placements, self.args)

	if self:_hasUsdPrizePool() then
		self:setConfig('showUSD', true)
		self:addPrize(PRIZE_TYPE_USD, 1, {roundPrecision = self.options.currencyRoundPrecision})

		if self.options.autoUSD then
			local canConvertCurrency = function(prize)
				return prize.type == PRIZE_TYPE_LOCAL_CURRENCY
			end

			for _, placement in ipairs(self.placements) do
				placement:_setUsdFromRewards(Array.filter(self.prizes, canConvertCurrency), PrizePool.prizeTypes)
			end
		end
	end

	table.sort(self.prizes, PrizePool._comparePrizes)

	return self
end

--- Compares the sort value of two prize entries
function PrizePool._comparePrizes(x, y)
	local sortX = PrizePool.prizeTypes[x.type].sortOrder
	local sortY = PrizePool.prizeTypes[y.type].sortOrder
	return sortX == sortY and x.index < y.index or sortX < sortY
end

function PrizePool:build()
	local wrapper = mw.html.create('div'):css('overflow-x', 'auto')

	if self.options.prizeSummary then
		wrapper:wikitext(self:_getPrizeSummaryText())
	end

	local table = WidgetTable{
		classes = {'collapsed', 'general-collapsible', 'prizepooltable'},
		css = {width = 'max-content'},
	}

	table:addRow(self:_buildHeader())

	for _, row in ipairs(self:_buildRows()) do
		table:addRow(row)
	end

	table:setContext{self._widgetInjector}
	for _, node in ipairs(WidgetFactory.work(table, self._widgetInjector)) do
		wrapper:node(node)
	end

	if self.options.exchangeInfo then
		wrapper:wikitext(self:_currencyExchangeInfo())
	end

	if self.options.storeLpdb or self.options.storeSmw then
		self:_storeData()
	end

	return wrapper
end

function PrizePool:_getPrizeSummaryText()
	local tba = Abbreviation.make('TBA', 'To Be Announced')
	local tournamentCurrency = Variables.varDefault('tournament_currency')
	local baseMoneyRaw = Variables.varDefault('tournament_prizepool_usd', tba)
	local baseMoneyDisplay = Currency.display(BASE_CURRENCY, baseMoneyRaw, {formatValue = true})

	local displayText = {baseMoneyDisplay}

	if tournamentCurrency and tournamentCurrency:upper() ~= BASE_CURRENCY then
		local localMoneyRaw = Variables.varDefault('tournament_prizepool_local', tba)
		local localMoneyDisplay = Currency.display(tournamentCurrency, localMoneyRaw, {formatValue = true})

		table.insert(displayText, 1, localMoneyDisplay)
		table.insert(displayText, 2,' (≃ ')
		table.insert(displayText, ')')
	end

	table.insert(displayText, ' are spread among the participants as seen below:')
	table.insert(displayText, '<br>')

	return table.concat(displayText)
end

function PrizePool:_buildHeader()
	local headerRow = TableRow{css = {['font-weight'] = 'bold'}}

	headerRow:addCell(TableCell{content = {'Place'}, css = {['min-width'] = '80px'}})

	local previousOfType = {}
	for _, prize in ipairs(self.prizes) do
		local prizeTypeData = self.prizeTypes[prize.type]

		if not prizeTypeData.mergeDisplayColumns or not previousOfType[prize.type] then
			local cell = prizeTypeData.headerDisplay(prize.data)
			headerRow:addCell(cell)
			previousOfType[prize.type] = cell
		end
	end

	headerRow:addCell(TableCell{content = {'Participant'}, classes = {'prizepooltable-col-team'}})

	return headerRow
end

function PrizePool:_buildRows()
	local rows = {}

	for _, placement in ipairs(self.placements) do
		local previousRow = {}

		for opponentIndex, opponent in ipairs(placement.opponents) do
			local row = TableRow{}

			if placement.placeStart > self.options.cutafter then
				row:addClass('ppt-hide-on-collapse')
			end

			row:addClass(placement:getBackground())

			if opponentIndex == 1 then
				local placeCell = TableCell{
					content = {{placement:getMedal() or '' , NON_BREAKING_SPACE, placement:_displayPlace()}},
					css = {['font-weight'] = 'bolder'},
				}
				placeCell.rowSpan = #placement.opponents
				row:addCell(placeCell)
			end

			local previousOfPrizeType = {}
			local prizeCells = Array.map(self.prizes, function (prize)
				local prizeTypeData = self.prizeTypes[prize.type]
				local reward = opponent.prizeRewards[prize.id] or placement.prizeRewards[prize.id]

				local cell
				if reward then
					cell = prizeTypeData.rowDisplay(prize.data, reward)
				end
				cell = cell or TableCell{}

				-- Update the previous column of this type in the same row
				local lastCellOfType = previousOfPrizeType[prize.type]
				if lastCellOfType and prizeTypeData.mergeDisplayColumns then

					if Table.isNotEmpty(lastCellOfType.content) and Table.isNotEmpty(cell.content) then
						lastCellOfType:addContent(tostring(mw.html.create('hr'):css('width', '100%')))
					end

					Array.extendWith(lastCellOfType.content, cell.content)
					lastCellOfType.css['flex-direction'] = 'column'

					return nil
				end

				previousOfPrizeType[prize.type] = cell
				return cell
			end)

			Array.forEach(prizeCells, function (prizeCell, columnIndex)
				local lastInColumn = previousRow[columnIndex]

				if Table.isEmpty(prizeCell.content) then
					prizeCell = PrizePool._emptyCell()
				end

				if lastInColumn and Table.deepEquals(lastInColumn.content, prizeCell.content) then
					lastInColumn.rowSpan = (lastInColumn.rowSpan or 1) + 1
				else
					previousRow[columnIndex] = prizeCell
					row:addCell(prizeCell)
				end
			end)

			local opponentDisplay = tostring(OpponentDisplay.BlockOpponent{
				opponent = opponent.opponentData,
				showPlayerTeam = true,
				abbreviateTbd = self.options.abbreviateTbd,
			})
			local opponentCss = {['justify-content'] = 'start'}

			row:addCell(TableCell{content = {opponentDisplay}, css = opponentCss})

			table.insert(rows, row)
		end

		if placement.placeStart <= self.options.cutafter
			and placement.placeEnd >= self.options.cutafter
			and placement ~= self.placements[#self.placements] then

			local toogleExpandRow = self:_toggleExpand(placement.placeEnd + 1, self.placements[#self.placements].placeEnd)
			table.insert(rows, toogleExpandRow)
		end
	end

	return rows
end

function PrizePool:_currencyExchangeInfo()
	if self.usedAutoConvertedCurrency then
		local currencyText = Currency.display(BASE_CURRENCY)
		local exchangeProvider = Abbreviation.make('exchange rate', Variables.varDefault('tournament_currency_text'))

		if not exchangeProvider then
			return
		end

		-- The exchange date display should not be in the future, as the extension uses current date for those.
		local exchangeDate = self.date
		if exchangeDate > TODAY then
			exchangeDate = TODAY
		end

		local exchangeDateText = LANG:formatDate('M j, Y', exchangeDate)

		local wrapper = mw.html.create('small')

		wrapper:wikitext('<br>\'\'(')
		wrapper:wikitext('Converted ' .. currencyText .. ' prizes are ')
		wrapper:wikitext('based on the ' .. exchangeProvider ..' on ' .. exchangeDateText .. ': ')
		wrapper:wikitext(table.concat(Array.map(Array.filter(self.prizes, function (prize)
			return PrizePool.prizeTypes[prize.type].convertToUsd
		end), PrizePool._CurrencyConvertionText), ', '))
		wrapper:wikitext('\'\')')

		return tostring(wrapper)
	end
end

function PrizePool._CurrencyConvertionText(prize)
	local exchangeRate = Math.round{
		PrizePool.prizeTypes[PRIZE_TYPE_LOCAL_CURRENCY].convertToUsd(
			prize.data, 1, PrizePool._getTournamentDate()
		)
		,5
	}

	return '1 ' .. Currency.display(prize.data.currency) .. ' ≃ ' .. exchangeRate .. ' ' .. Currency.display(BASE_CURRENCY)
end

function PrizePool:_toggleExpand(placeStart, placeEnd)
	local text = 'place ' .. placeStart .. ' to ' .. placeEnd
	local expandButton = TableCell{content = {'<div>' .. text .. '&nbsp;<i class="fa fa-chevron-down"></i></div>'}}
		:addClass('general-collapsible-expand-button')
	local collapseButton = TableCell{content = {'<div>' .. text .. '&nbsp;<i class="fa fa-chevron-up"></i></div>'}}
		:addClass('general-collapsible-collapse-button')

	return TableRow{classes = {'ppt-toggle-expand'}}:addCell(expandButton):addCell(collapseButton)
end

function PrizePool:_readConfig(args)
	for name, configData in pairs(self.config) do
		local value = configData.default
		if configData.read then
			value = Logic.nilOr(configData.read(args), value)
		end
		self:setConfig(name, value)
	end

	return self.options
end

--- Parse the input for available prize types overall.
function PrizePool:_readPrizes(args)
	for name, prizeData in pairs(self.prizeTypes) do
		local fieldName = prizeData.header
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, prizeValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				local data = prizeData.headerParse(self, prizeValue, args, index)
				self:addPrize(name, index, data)
			end
		end
	end

	return self.prizes
end

function PrizePool:_readPlacements(args)
	local currentPlace = 0
	return Array.mapIndexes(function(placementIndex)
		if not args[placementIndex] then
			return
		end

		local placementInput = Json.parseIfString(args[placementIndex])
		local placement = Placement(placementInput, self, currentPlace)

		currentPlace = placement.placeEnd

		return placement
	end)
end

function PrizePool:setConfig(option, value)
	self.options[option] = value
	return self
end

function PrizePool:addCustomConfig(name, default, func)
	self.config[name] = {
		default = default,
		read = func
	}
	return self
end

--- Add a Custom Prize Type
function PrizePool:addCustomPrizeType(prizeType, data)
	self.prizeTypes[prizeType] = data
	return self
end

function PrizePool:addPrize(prizeType, index, data)
	assert(self.prizeTypes[prizeType], 'addPrize: Not a valid prize!')
	assert(Logic.isNumeric(index), 'addPrize: Index is not numeric!')
	table.insert(self.prizes, {id = prizeType .. index, type = prizeType, index = index, data = data})
	return self
end

--- Set the WidgetInjector.
-- @param widgetInjector WidgetInjector An instance of a class that implements the WidgetInjector interface
function PrizePool:setWidgetInjector(widgetInjector)
	assert(widgetInjector:is_a(WidgetInjector), "setWidgetInjector: Not a Widget Injector")
	self._widgetInjector = widgetInjector
	return self
end

--- Set the LpdbInjector.
-- @param lpdbInjector LpdbInjector An instance of a class that implements the LpdbInjector interface
function PrizePool:setLpdbInjector(lpdbInjector)
	assert(lpdbInjector:is_a(LpdbInjector), "setLpdbInjector: Not an LPDB Injector")
	self._lpdbInjector = lpdbInjector
	return self
end

--- Set the SmwInjector.
-- @param smwInjector SmwInjector An instance of a class that implements the SmwInjector interface
function PrizePool:setSmwInjector(smwInjector)
	assert(smwInjector:is_a(SmwInjector), "setSmwInjector: Not an SMW Injector")
	self._smwInjector = smwInjector
	return self
end

function PrizePool:_storeData()
	local prizePoolIndex = (tonumber(Variables.varDefault('prizepool_index')) or 0) + 1
	Variables.varDefine('prizepool_index', prizePoolIndex)

	local lpdbTournamentData = {
		tournament = Variables.varDefault('tournament_name'),
		parent = Variables.varDefault('tournament_parent'),
		series = Variables.varDefault('tournament_series'),
		shortname = Variables.varDefault('tournament_tickername'),
		startdate = Variables.varDefaultMulti('tournament_startdate', 'tournament_sdate', 'sdate', ''),
		mode = Variables.varDefault('tournament_mode'),
		type = Variables.varDefault('tournament_type'),
		liquipediatier = Variables.varDefault('tournament_liquipediatier'),
		liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
		icon = Variables.varDefault('tournament_icon'),
		icondark = Variables.varDefault('tournament_icondark'),
		game = Variables.varDefault('tournament_game'),
		prizepoolindex = prizePoolIndex,
	}

	local lpdbData = {}
	for _, placement in ipairs(self.placements) do
		local lpdbEntries = placement:_getLpdbData(prizePoolIndex, self.options.lpdbPrefix)

		lpdbEntries = Array.map(lpdbEntries, function(lpdbEntry) return Table.merge(lpdbTournamentData, lpdbEntry) end)

		Array.extendWith(lpdbData, lpdbEntries)
	end

	local smwTournamentStash = {}
	for _, lpdbEntry in ipairs(lpdbData) do
		if self.options.storeSmw then
			smwTournamentStash = self:_storeSmw(lpdbEntry, smwTournamentStash)
		end

		lpdbEntry.players = mw.ext.LiquipediaDB.lpdb_create_json(lpdbEntry.players or {})
		lpdbEntry.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbEntry.extradata or {})

		if self.options.storeLpdb then
			mw.ext.LiquipediaDB.lpdb_placement(lpdbEntry.objectName, lpdbEntry)
		end
	end

	if Table.isNotEmpty(smwTournamentStash) then
		tournamentVars:set('smwRecords.tournament', Json.stringify(smwTournamentStash))
	end

	return self
end

function PrizePool:_storeSmw(lpdbEntry, smwTournamentStash)
	local smwEntry = self:_lpdbToSmw(lpdbEntry)

	if self._smwInjector then
		smwEntry = self._smwInjector:adjust(smwEntry, lpdbEntry)
	end

	local count = (tonumber(tournamentVars:get('smwRecords.count')) or 0) + 1
	tournamentVars:set('smwRecords.count', count)
	tournamentVars:set('smwRecords.' .. count .. '.id', Table.extract(smwEntry, 'objectName'))
	tournamentVars:set('smwRecords.' .. count .. '.data', Json.stringify(smwEntry))

	local place = smwEntry['has placement']
	if place and not Placement.specialStatuses[string.upper(place)] then
		local key = 'has '
		if String.isNotEmpty(self.options.lpdbPrefix) then
			key = key .. self.options.lpdbPrefix .. ' '
		end
		place = mw.text.split(place, '-')[1]
		key = key .. Template.safeExpand(mw.getCurrentFrame(), 'OrdinalWritten/' .. place, {}, '')
		if lpdbEntry.opponentindex ~= 1 then
			key = key .. lpdbEntry.opponentindex
		end
		key = key .. ' place page'

		smwTournamentStash[key] = lpdbEntry.participant
	end

	return smwTournamentStash
end

function PrizePool:_lpdbToSmw(lpdbData)
	local smwOpponentData = {}
	if lpdbData.opponenttype == Opponent.team then
		smwOpponentData['has team page'] = lpdbData.participant
	elseif lpdbData.opponenttype == Opponent.literal then
		smwOpponentData['has literal team'] = lpdbData.participant
	elseif lpdbData.opponenttype == Opponent.solo then
		local playersData = Json.parseIfString(lpdbData.players) or {}
		smwOpponentData = {
			['has player id'] = lpdbData.participant,
			['has player page'] = lpdbData.participantlink,
			['has flag'] = lpdbData.participantflag,
			['has team page'] = playersData.p1team,
			['has team'] = playersData.p1team,
		}
	end

	local scoreData = {
		['has last wdl'] = lpdbData.groupscore,
	}
	if Table.includes(SPECIAL_SCORES, lpdbData.lastscore) then
		if lpdbData.lastscore == WALKOVER_SCORE then
			scoreData['has walkover from'] = lpdbData.lastvs
		elseif lpdbData.lastscore == FORFEIT_SCORE then
			scoreData['has walkover to'] = lpdbData.lastvs
		end
	else
		scoreData['has last score'] = lpdbData.lastscore
		scoreData['has last opponent score'] = lpdbData.lastvsscore
	end

	return Table.mergeInto({
			objectName = lpdbData.objectName,

			['has tournament page'] = lpdbData.parent,
			['has tournament name'] = lpdbData.tournament,
			['has tournament type'] = lpdbData.type,
			['has tournament series'] = lpdbData.series,
			['has icon'] = lpdbData.icon,
			['is result type'] = lpdbData.mode,
			['has game'] = lpdbData.game,
			['has date'] = lpdbData.date,
			['is tier'] = lpdbData.liquipediatier,
			['has placement'] = lpdbData.placement,
			['has prizemoney'] = lpdbData.prizemoney,
			['has last opponent'] = lpdbData.lastvs,
			['has weight'] = lpdbData.weight,
		},
		smwOpponentData,
		scoreData
	)
end

-- get the lpdbObjectName depending on opponenttype
function PrizePool:_lpdbObjectName(lpdbEntry, prizePoolIndex, lpdbPrefix)
	local objectName = 'ranking'
	if String.isNotEmpty(lpdbPrefix) then
		objectName = objectName .. '_' .. lpdbPrefix
	end
	if lpdbEntry.opponenttype == Opponent.team then
		return objectName .. '_' .. mw.ustring.lower(lpdbEntry.participant)
	end
	-- for non team opponents the pagename can be case sensitive
	-- so objectname needs to be case sensitive to avoid edge cases
	return objectName .. prizePoolIndex .. '_' .. lpdbEntry.participant
end

--- Returns true if this prizePool has a US Dollar reward.
-- This is true if any placement has a dollar input,
-- or if there is a money reward in another currency whilst currency conversion is active
function PrizePool:_hasUsdPrizePool()
	return (Array.any(self.placements, function (placement)
		return placement.hasUSD
	end)) or (self.options.autoUSD and Array.any(self.prizes, function (prize)
		return prize.type == PRIZE_TYPE_LOCAL_CURRENCY
	end))
end

--- Creates an empty table cell
function PrizePool._emptyCell()
	return TableCell{content = {DASH}}
end

--- Remove all non-numeric characters from an input and changes it to a number.
-- Most commonly used on money inputs, as they often contain , or .
function PrizePool._parseInteger(input)
	if type(input) == 'number' then
		return input
	elseif type(input) == 'string' then
		return tonumber((input:gsub('[^%d.]', '')))
	end
end

--- Asserts that an Opponent Struct is valid and has a valid type
function PrizePool:assertOpponentStructType(typeStruct)
	if not typeStruct then
		error('Please provide a type!')
	elseif type(typeStruct) ~= 'table' or not typeStruct.type then
		error('Could not parse type!')
	elseif not Opponent.isType(typeStruct.type) then
		error('Not a valid type!')
	end
end

--- Fetches the LPDB object of a tournament
function PrizePool._getTournamentInfo(pageName)
	return mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. pageName .. ']]',
		limit = 1,
	})[1]
end

--- Returns the default date based on wiki-variables set in the Infobox League
function PrizePool._getTournamentDate()
	return Variables.varDefaultMulti('tournament_enddate', 'tournament_edate', 'edate', TODAY)
end

return PrizePool
