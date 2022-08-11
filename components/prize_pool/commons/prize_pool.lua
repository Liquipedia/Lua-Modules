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
local MatchPlacement = require('Module:Match/Placement')
local Math = require('Module:Math')
---Note: This can be overwritten
local Opponent = require('Module:Opponent')
---Note: This can be overwritten
local OpponentDisplay = require('Module:OpponentDisplay')
local Ordinal = require('Module:Ordinal')
local PlacementInfo = require('Module:Placement')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local WidgetInjector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local WidgetFactory = require('Module:Infobox/Widget/Factory')
local WidgetTable = require('Module:Widget/Table')
local TableRow = require('Module:Widget/Table/Row')
local TableCell = require('Module:Widget/Table/Cell')

--- @class PrizePool
local PrizePool = Class.new(function(self, ...) self:init(...) end)

--- @class Placement
--- A Placement is a set of opponents who all share the same final place in the tournament.
--- Its input is generally a table created by `Template:Placement`.
--- It has a range from placeStart to placeEnd, for example 5 to 8
--- and is expected to have the same amount of opponents as the range allows (4 is the 5-8 example).
local Placement = Class.new(function(self, ...) self:init(...) end)

local TODAY = os.date('%Y-%m-%d')

local LANG = mw.language.getContentLanguage()
local DASH = '&#045;'
local NON_BREAKING_SPACE = '&nbsp;'
local BASE_CURRENCY = 'USD'

local PRIZE_TYPE_USD = 'USD'
local PRIZE_TYPE_LOCAL_CURRENCY = 'LOCAL_CURRENCY'
local PRIZE_TYPE_QUALIFIES = 'QUALIFIES'
local PRIZE_TYPE_POINTS = 'POINTS'
local PRIZE_TYPE_FREETEXT = 'FREETEXT'

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
	},
	storeLpdb = {
		default = true,
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
				return TableCell{content = {{'$', Currency.formatMoney(data)}}}
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
				rate = currencyRate or 0,
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
				local displayText = {Currency.formatMoney(data)}

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
			local pointsData = mw.loadData('Module:Points/data')
			return pointsData[input] or {title = 'Points'}
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

PrizePool.additionalData = {
	GROUPSCORE = {
		field = 'wdl',
		parse = function (placement, input, context)
			return input
		end
	},
	LASTVS = {
		field = 'lastvs',
		parse = function (placement, input, context)
			return placement:_parseOpponentArgs(input, context.date)
		end
	},
	LASTVSSCORE = {
		field = 'lastvsscore',
		parse = function (placement, input, context)
			local scores = Table.mapValues(mw.text.split(input, '-'), tonumber)
			return {score = scores[1], vsscore = scores[2]}
		end
	},
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
}

function PrizePool:init(args)
	self.args = self:_parseArgs(args)

	self.pagename = mw.title.getCurrentTitle().text
	self.date = PrizePool._getTournamentDate()
	self.opponentType = self.args.type
	if self.args.opponentLibrary then
		Opponent = require('Module:'.. self.args.opponentLibrary)
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

	PrizePool._assertOpponentStructType(typeStruct)

	parsedArgs.type = typeStruct.type

	return parsedArgs
end

function PrizePool:create()
	self.options = self:_readConfig(self.args)
	self.prizes = self:_readPrizes(self.args)
	self.placements = self:_readPlacements(self.args)

	if self:_hasUsdPrizePool() then
		self:setConfig('showUSD', true)
		self:addPrize(PRIZE_TYPE_USD, 1)

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
	return PrizePool.prizeTypes[x.type].sortOrder < PrizePool.prizeTypes[y.type].sortOrder
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

	table.insert(displayText, ' are spread among the teams as seen below:')
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
					content = {{placement:getMedal() or '' , NON_BREAKING_SPACE, placement.placeDisplay}},
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
				showPlayerTeam = true
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
		local lpdbEntries = placement:_getLpdbData()

		Array.forEach(lpdbEntries, function(lpdbEntry) Table.mergeInto(lpdbEntry, lpdbTournamentData) end)

		Array.extendWith(lpdbData, lpdbEntries)
	end

	for _, lpdbEntry in ipairs(lpdbData) do
		lpdbEntry.players = mw.ext.LiquipediaDB.lpdb_create_json(lpdbEntry.players or {})
		lpdbEntry.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbEntry.extradata or {})

		if self.options.storeLpdb then
			mw.ext.LiquipediaDB.lpdb_placement(PrizePool:_lpdbObjectName(lpdbEntry, prizePoolIndex), lpdbEntry)
		end

		if self.options.storeSmw then
			Template.safeExpand(mw.getCurrentFrame(), 'PrizePoolSmwStorage', lpdbEntry)
		end
	end

	return self
end

-- get the lpdbObjectName depending on opponenttype
function PrizePool:_lpdbObjectName(lpdbEntry, prizePoolIndex)
	local objectName = 'ranking_'
	if lpdbEntry.opponenttype == Opponent.team then
		local smwPrefix = Variables.varDefault('smw_prefix', '')
		return objectName .. smwPrefix .. mw.ustring.lower(lpdbEntry.participant)
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

--- Returns true if the input matches the format of a date
function PrizePool._isValidDateFormat(date)
	if type(date) ~= 'string' or String.isEmpty(date) then
		return false
	end
	return date:match('%d%d%d%d%-%d%d%-%d%d') and true or false
end

--- Asserts that an Opponent Struct is valid and has a valid type
function PrizePool._assertOpponentStructType(typeStruct)
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

--- @class Placement
--- @param args table Input information
--- @param parent PrizePool The PrizePool this Placement is part of
--- @param lastPlacement integer The previous placement's end
function Placement:init(args, parent, lastPlacement)
	self.args = self:_parseArgs(args)
	self.date = self.args.date or PrizePool._getTournamentDate()
	self.placeStart = self.args.placeStart
	self.placeEnd = self.args.placeEnd
	self.parent = parent
	self.hasUSD = false

	self.prizeRewards = self:_readPrizeRewards(self.args)

	self.opponents = self:_parseOpponents(self.args)

	-- Implicit place range has been given (|place= is not set)
	-- Use the last known place and set the place range based on the entered number of opponents
	if not self.placeStart and not self.placeEnd then
		self.placeStart = lastPlacement + 1
		self.placeEnd = lastPlacement + #self.opponents
	end

	assert(#self.opponents > self.placeEnd - self.placeStart, 'Placement: Too many opponents')

	self.placeDisplay = self:_displayPlace()
end

function Placement:_parseArgs(args)
	local parsedArgs = Table.deepCopy(args)

	-- Explicit place range has been given
	if args.place then
		local places = Table.mapValues(mw.text.split(args.place, '-'), tonumber)
		parsedArgs.placeStart = places[1]
		parsedArgs.placeEnd = places[2] or places[1]
		assert(parsedArgs.placeStart and parsedArgs.placeEnd, 'Placement: Invalid |place= provided.')
	end

	return parsedArgs
end

--- Parse the input for available rewards of prizes, for instance how much money a team would win.
--- This also checks if the Placement instance has a dollar reward and assigns a variable if so.
function Placement:_readPrizeRewards(args)
	local rewards = {}

	-- Loop through all prizes that have been defined in the header
	Array.forEach(self.parent.prizes, function (prize)
		local prizeData = self.parent.prizeTypes[prize.type]
		local fieldName = prizeData.row
		if not fieldName then
			return
		end

		local prizeIndex = prize.index
		local reward = args[fieldName .. prizeIndex]
		if prizeIndex == 1 then
			reward = reward or args[fieldName]
		end
		if not reward then
			return
		end

		rewards[prize.id] = prizeData.rowParse(self, reward, args, prizeIndex)
	end)

	-- Special case for USD, as it's not defined in the header.
	local usdType = self.parent.prizeTypes[PRIZE_TYPE_USD]
	if usdType.row and args[usdType.row] then
		self.hasUSD = true
		rewards[PRIZE_TYPE_USD .. 1] = usdType.rowParse(self, args[usdType.row], args, 1)
	end

	return rewards
end

--- Parse and set additional data fields for opponents.
-- This includes fields such as group stage score (wdl) and last versus (lastvs).
function Placement:_readAdditionalData(args)
	local data = {}

	for prizeType, typeData in pairs(self.parent.additionalData) do
		local fieldName = typeData.field
		if args[fieldName] then
			data[prizeType] = typeData.parse(self, args[fieldName], args)
		end
	end

	return data
end

function Placement:_parseOpponents(args)
	return Array.mapIndexes(function(opponentIndex)
		local opponentInput = Json.parseIfString(args[opponentIndex])
		local opponent = {opponentData = {}, prizeRewards = {}, additionalData = {}}
		if not opponentInput then
			-- If given a range of opponents, add them all, even if they're missing from the input
			if not args.place or self.placeStart + opponentIndex > self.placeEnd + 1 then
				return
			else
				opponent.opponentData = Opponent.tbd(self.parent.opponentType)
			end
		else
			-- Set the date
			if not PrizePool._isValidDateFormat(opponentInput.date) then
				opponentInput.date = self.date
			end

			-- Parse Opponent Data
			if opponentInput.type then
				PrizePool._assertOpponentStructType(opponentInput)
			else
				opponentInput.type = self.parent.opponentType
			end
			opponent.opponentData = self:_parseOpponentArgs(opponentInput, opponentInput.date)

			opponent.prizeRewards = self:_readPrizeRewards(opponentInput)
			opponent.additionalData = self:_readAdditionalData(opponentInput)

			-- Set date
			opponent.date = opponentInput.date
		end
		return opponent
	end)
end

function Placement:_parseOpponentArgs(input, date)
	-- Allow for lua-table, json-table and just raw string input
	local opponentArgs = Json.parseIfTable(input) or (type(input) == 'table' and input or {input})
	opponentArgs.type = opponentArgs.type or self.parent.opponentType
	assert(Opponent.isType(opponentArgs.type), 'Invalid type')

	local opponentData = Opponent.readOpponentArgs(opponentArgs)

	if not opponentData or Opponent.isTbd(opponentData) then
		opponentData = Opponent.tbd(opponentArgs.type)
	end

	return Opponent.resolve(opponentData, date, {syncPlayer = self.parent.options.syncPlayers})
end

function Placement:_getLpdbData()
	local entries = {}
	for _, opponent in ipairs(self.opponents) do
		local participant, image, imageDark, players
		local playerCount = 0
		local opponentType = opponent.opponentData.type

		if opponentType == Opponent.team then
			local teamTemplate = mw.ext.TeamTemplate.raw(opponent.opponentData.template)

			participant = ''
			if teamTemplate then
				participant = teamTemplate.page
				if self.parent.options.resolveRedirect then
					participant = mw.ext.TeamLiquidIntegration.resolve_redirect(participant)
				end

				image = teamTemplate.image
				imageDark = teamTemplate.imagedark
			end
		elseif opponentType == Opponent.solo then
			participant = Opponent.toName(opponent.opponentData)
			local p1 = opponent.opponentData.players[1]
			players = {p1 = p1.pageName, p1dn = p1.displayName, p1flag = p1.flag, p1team = p1.team}
			playerCount = 1
		else
			participant = Opponent.toName(opponent.opponentData)
		end

		local prizeMoney = tonumber(self:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_USD .. 1)) or 0
		local pointsReward = self:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1)
		local lpdbData = {
			image = image,
			imagedark = imageDark,
			date = opponent.date,
			participant = participant,
			participantlink = Opponent.toName(opponent.opponentData),
			participantflag = opponentType == Opponent.solo and players.p1flag or nil,
			participanttemplate = opponent.opponentData.template,
			opponenttype = opponentType,
			players = players,
			placement = self:_lpdbValue(),
			prizemoney = prizeMoney,
			individualprizemoney = (playerCount > 0) and (prizeMoney / playerCount) or 0,
			lastvs = Opponent.toName(opponent.additionalData.LASTVS or {}),
			lastscore = (opponent.additionalData.LASTVSSCORE or {}).score,
			lastvsscore = (opponent.additionalData.LASTVSSCORE or {}).vsscore,
			groupscore = opponent.additionalData.GROUPSCORE,
			extradata = {
				prizepoints = tostring(pointsReward or ''),
			}

			-- TODO: We need to create additional LPDB Fields
			-- match2 opponents (opponentname, opponenttemplate, opponentplayers, opponenttype)
			-- Qualified To struct (json?)
			-- Points struct (json?)
			-- lastvs match2 opponent (json?)
		}

		if self.parent._lpdbInjector then
			lpdbData = self.parent._lpdbInjector:adjust(lpdbData, self, opponent)
		end

		table.insert(entries, lpdbData)
	end

	return entries
end

function Placement:getPrizeRewardForOpponent(opponent, prize)
	return opponent.prizeRewards[prize] or self.prizeRewards[prize]
end

function Placement:_setUsdFromRewards(prizesToUse, prizeTypes)
	Array.forEach(self.opponents, function(opponent)
		if opponent.prizeRewards[PRIZE_TYPE_USD .. 1] or self.prizeRewards[PRIZE_TYPE_USD .. 1] then
			return
		end

		local usdReward = 0
		Array.forEach(prizesToUse, function(prize)
			local localMoney = opponent.prizeRewards[prize.id] or self.prizeRewards[prize.id]

			if not localMoney or localMoney <= 0 then
				return
			end

			usdReward = usdReward + prizeTypes[prize.type].convertToUsd(
				prize.data,
				localMoney,
				opponent.date,
				self.parent.options.currencyRatePerOpponent
			)
			self.parent.usedAutoConvertedCurrency = true
		end)

		opponent.prizeRewards[PRIZE_TYPE_USD .. 1] = usdReward
	end)
end

function Placement:_lpdbValue()
	for _, status in pairs(Placement.specialStatuses) do
		if status.active(self.args) then
			return status.lpdb
		end
	end

	if self.placeEnd > self.placeStart then
		return self.placeStart .. '-' .. self.placeEnd
	end

	return self.placeStart
end

function Placement:_displayPlace()
	for _, status in pairs(Placement.specialStatuses) do
		if status.active(self.args) then
			return status.display()
		end
	end

	local start = Ordinal._ordinal(self.placeStart)
	if self.placeEnd > self.placeStart then
		return start .. DASH .. Ordinal._ordinal(self.placeEnd)
	end

	return start
end

function Placement:getBackground()
	if Placement.specialStatuses.DQ.active(self.args) then
		return 'background-color-disqualified'
	end

	return PlacementInfo.getBgClass(self.placeStart)
end

function Placement:getMedal()
	local medal = MatchPlacement.MedalIcon{range = {self.placeStart, self.placeEnd}}
	if medal then
		return tostring(medal)
	end
end

return PrizePool
