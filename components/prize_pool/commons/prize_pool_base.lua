---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Currency = Lua.import('Module:Currency')
local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local WidgetInjector = Lua.import('Module:Infobox/Widget/Injector')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Widgets = require('Module:Infobox/Widget/All')
local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory')
local WidgetTable = Widgets.Table
local TableRow = Widgets.TableRow
local TableCell = Widgets.TableCell

local pageVars = PageVariableNamespace('PrizePool')

--- @class BasePrizePool
local BasePrizePool = Class.new(function(self, ...) self:init(...) end)

---@class BasePrizePoolPrize
---@field id string
---@field type string
---@field index integer
---@field data table

local TODAY = os.date('%Y-%m-%d') --[[@as string]]

local LANG = mw.language.getContentLanguage()
local DASH = '&#045;'
local NON_BREAKING_SPACE = '&nbsp;'
local BASE_CURRENCY = 'USD'
local EXCHANGE_SUMMARY_PRECISION = 5

local PRIZE_TYPE_BASE_CURRENCY = 'BASE_CURRENCY'
local PRIZE_TYPE_LOCAL_CURRENCY = 'LOCAL_CURRENCY'
local PRIZE_TYPE_QUALIFIES = 'QUALIFIES'
local PRIZE_TYPE_POINTS = 'POINTS'
local PRIZE_TYPE_PERCENTAGE = 'PERCENT'
local PRIZE_TYPE_FREETEXT = 'FREETEXT'

BasePrizePool.config = {
	showBaseCurrency = {
		default = false
	},
	autoExchange = {
		default = true,
		read = function(args)
			return Logic.readBoolOrNil(args.autoexchange or args.autousd)
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
	storeLpdb = {
		default = true,
		read = function(args)
			local disabledVariable = Logic.readBoolOrNil(Variables.varDefault('disable_LPDB_storage'))
			if disabledVariable ~= nil then
				disabledVariable = not disabledVariable
			end
			return Logic.nilOr(
				Logic.readBoolOrNil(args.storelpdb),
				disabledVariable
			)
		end
	},
	resolveRedirect = {
		default = false,
		read = function(args)
			return Logic.readBoolOrNil(args.resolveRedirect)
		end
	},
	syncPlayers = {
		default = true,
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
			return args.lpdb_prefix or Variables.varDefault('lpdb_prefix')
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
}

BasePrizePool.prizeTypes = {
	[PRIZE_TYPE_BASE_CURRENCY] = {
		sortOrder = 10,

		headerDisplay = function (data)
			local currencyText = Currency.display(BASE_CURRENCY)
			return TableCell{content = {{currencyText}}}
		end,

		row = BASE_CURRENCY:lower() .. 'prize',
		rowParse = function (placement, input, context, index)
			return BasePrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{content = {
					Currency.display(BASE_CURRENCY, data,
						{formatValue = true, formatPrecision = headerData.roundPrecision, displayCurrencyCode = false})
				}}
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

			local currencyRate = Currency.getExchangeRate{
				currency = currencyData.code,
				currencyRate = Variables.varDefault('exchangerate_' .. currencyData.code),
				date = prizePool.date,
				setVariables = true,
			}

			return {
				currency = currencyData.code, rate = currencyRate or 0,
				roundPrecision = prizePool.options.currencyRoundPrecision,
			}
		end,
		headerDisplay = function (data)
			return TableCell{content = {{Currency.display(data.currency)}}}
		end,

		row = 'localprize',
		rowParse = function (placement, input, context, index)
			return BasePrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{content = {
					Currency.display(headerData.currency, data,
					{formatValue = true, formatPrecision = headerData.roundPrecision, displayCurrencyCode = false})
				}}
			end
		end,

		convertToBaseCurrency = function (headerData, data, date, perOpponent)
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
	[PRIZE_TYPE_PERCENTAGE] = {
		sortOrder = 30,

		header = 'percentage',
		headerParse = function (prizePool, input, context, index)
			assert(index == 1, 'Percentage only supports index 1')
			return {title = 'Percentage'}
		end,
		headerDisplay = function (data)
			return TableCell{content = {{data.title}}}
		end,

		row = 'percentage',
		rowParse = function (placement, input, context, index)
			local value = BasePrizePool._parseInteger(input)
			if value then
				placement.hasPercentage = true
			end

			return value
		end,
		rowDisplay = function (headerData, data)
			if String.isNotEmpty(data) then
				return TableCell{content = {{data .. '%'}}}
			end
		end,
	},
	[PRIZE_TYPE_QUALIFIES] = {
		sortOrder = 40,

		header = 'qualifies',
		headerParse = function (prizePool, input, context, index)
			local link = mw.ext.TeamLiquidIntegration.resolve_redirect(input):gsub(' ', '_')

			-- Automatically retrieve information from the Tournament
			local tournamentData = BasePrizePool._getTournamentInfo(link) or {}
			local prefix = 'qualifies' .. index
			return {
				link = link,
				title = context[prefix .. 'name'] or Logic.emptyOr(
					tournamentData.tickername,
					tournamentData.name,
					(tournamentData.pagename or link):gsub('_', ' '):gsub('/', ' ')
				),
				icon = tournamentData.icon or context[prefix .. 'icon'],
				iconDark = tournamentData.icondark or context[prefix .. 'icondark']
			}
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
		sortOrder = 50,

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
			return BasePrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{content = {{LANG:formatNum(data)}}}
			end
		end,
	},
	[PRIZE_TYPE_FREETEXT] = {
		sortOrder = 60,

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

---@param args table
---@return self
function BasePrizePool:init(args)
	self.args = self:_parseArgs(args)

	self.pagename = mw.title.getCurrentTitle().text
	self.date = BasePrizePool._getTournamentDate()
	self.opponentType = self.args.type

	self.options = {}
	self.prizes = {}
	self.placements = {}

	self.usedAutoConvertedCurrency = false

	self.adjacentContent = Logic.emptyOr(args.adjacentContent)

	return self
end

---@param args table
---@return table
function BasePrizePool:_parseArgs(args)
	local parsedArgs = Table.deepCopy(args)
	local typeStruct = Json.parseIfString(args.type)

	self:assertOpponentStructType(typeStruct)

	parsedArgs.type = typeStruct.type

	return parsedArgs
end

---@return self
function BasePrizePool:create()
	self.options = self:_readConfig(self.args)
	self.prizes = self:_readPrizes(self.args)
	self:readPlacements(self.args)

	if self:_hasBaseCurrency() then
		self:setConfig('showBaseCurrency', true)
		self:addPrize(PRIZE_TYPE_BASE_CURRENCY, 1, {roundPrecision = self.options.currencyRoundPrecision})

		if self.options.autoExchange then
			local canConvertCurrency = function(prize)
				return prize.type == PRIZE_TYPE_LOCAL_CURRENCY
			end
			local hasLocalCurrency1 = Array.any(self.prizes, function(prize)
				return canConvertCurrency(prize) and prize.index == 1
			end)
			local hasPercentage1 = Array.any(self.prizes, function(prize)
				return prize.type == PRIZE_TYPE_PERCENTAGE and prize.index == 1
			end)

			for _, placement in ipairs(self.placements) do
				if hasPercentage1 then placement:_calculateFromPercentage(BasePrizePool.prizeTypes, hasLocalCurrency1) end
				placement:_setBaseFromRewards(Array.filter(self.prizes, canConvertCurrency), BasePrizePool.prizeTypes)
			end
		end
	end

	table.sort(self.prizes, BasePrizePool._comparePrizes)

	return self
end

---@param args table
function BasePrizePool:readPlacements(args)
	error('Function readPlacements needs to be implemented by a child class of "Module:PrizePool/Base"')
end

---@param args table
---@return table
function BasePrizePool:_readConfig(args)
	for name, configData in pairs(self.config) do
		local value = configData.default
		if configData.read then
			value = Logic.nilOr(configData.read(args), value)
		end
		self:setConfig(name, value)
	end

	return self.options
end

---@param option string
---@param value string|number|boolean
---@return self
function BasePrizePool:setConfig(option, value)
	self.options[option] = value
	return self
end

---@param option string
---@param value string|number|boolean
---@return self
function BasePrizePool:setConfigDefault(option, value)
	if self.config[option] then
		self.config[option].default = value
	else
		error('Invalid default config override!')
	end
	return self
end

---@param name string
---@param default string|number|boolean
---@param func function?
---@return self
function BasePrizePool:addCustomConfig(name, default, func)
	self.config[name] = {
		default = default,
		read = func
	}
	return self
end

--- Parse the input for available prize types overall.
---@param args table
---@return BasePrizePoolPrize[]
function BasePrizePool:_readPrizes(args)
	for name, prizeData in pairs(self.prizeTypes) do
		local fieldName = prizeData.header
		if fieldName then
			for _, prizeValue, index in Table.iter.pairsByPrefix(args, fieldName, {requireIndex = false}) do
				local data = prizeData.headerParse(self, prizeValue, args, index)
				self:addPrize(name, index, data)
			end
		end
	end

	return self.prizes
end

---@param prizeType string
---@param index integer
---@param data table
---@return self
function BasePrizePool:addPrize(prizeType, index, data)
	assert(self.prizeTypes[prizeType], 'addPrize: Not a valid prize!')
	assert(Logic.isNumeric(index), 'addPrize: Index is not numeric!')
	table.insert(self.prizes, {id = prizeType .. index, type = prizeType, index = index, data = data})
	return self
end

--- Add a Custom Prize Type
---@param prizeType string
---@param data table
---@return self
function BasePrizePool:addCustomPrizeType(prizeType, data)
	self.prizeTypes[prizeType] = data
	return self
end

--- Compares the sort value of two prize entries
---@param x BasePrizePoolPrize
---@param y BasePrizePoolPrize
---@return boolean
function BasePrizePool._comparePrizes(x, y)
	local sortX = BasePrizePool.prizeTypes[x.type].sortOrder
	local sortY = BasePrizePool.prizeTypes[y.type].sortOrder
	return sortX == sortY and x.index < y.index or sortX < sortY
end

---@return boolean?
function BasePrizePool:_shouldDisplayPrizeSummary()
	-- if prizeSummary is disabled do not show it
	if not self.options.prizeSummary then
		return false
	end

	local baseMoney = tonumber(Variables.varDefault('tournament_prizepool' .. BASE_CURRENCY:lower()))
	-- if we have currency conversion (i.e. entered `localcurrency`) or entered usd values display it
	-- if we have baseMoney being not 0 display it
	-- if we have unset baseMoney display it (usually TBA/TBD case)
	if self.options.showBaseCurrency or baseMoney ~= 0 then
		return true
	end
end

---@param isAward boolean?
---@return Html
function BasePrizePool:build(isAward)
	local prizePoolTable = self:_buildTable(isAward)

	if self.options.storeLpdb then
		self:storeData()
	end

	if not (self.options.exchangeInfo or self.adjacentContent or self:_shouldDisplayPrizeSummary()) then
		return prizePoolTable
	end

	local wrapper = mw.html.create('div'):addClass('prizepool-section-wrapper')

	if self:_shouldDisplayPrizeSummary() then
		wrapper:tag('span'):wikitext(self:_getPrizeSummaryText())
	end

	local tablesWrapper = mw.html.create('div'):addClass('prizepool-section-tables'):node(prizePoolTable)

	if self.adjacentContent then
		tablesWrapper:wikitext(self.adjacentContent)
	end

	wrapper:node(tablesWrapper)

	if self.options.exchangeInfo then
		wrapper:wikitext(self:_currencyExchangeInfo())
	end

	return wrapper
end

---@param isAward boolean?
---@return Html
function BasePrizePool:_buildTable(isAward)
	local tbl = WidgetTable{
		classes = {'collapsed', 'general-collapsible', 'prizepooltable'},
		css = {width = 'max-content'},
	}

	local headerRow = self:_buildHeader(isAward)

	tbl:addRow(headerRow)

	tbl.columns = headerRow:getCellCount()

	for _, row in ipairs(self:_buildRows()) do
		tbl:addRow(row)
	end

	local tableNode = mw.html.create('div'):css('overflow-x', 'auto')
	for _, node in ipairs(WidgetFactory.work(tbl, self._widgetInjector)) do
		tableNode:node(node)
	end

	return tableNode
end

---@param isAward boolean?
---@return WidgetTableRow
function BasePrizePool:_buildHeader(isAward)
	local headerRow = TableRow{classes = {'prizepooltable-header'}, css = {['font-weight'] = 'bold'}}

	headerRow:addCell(TableCell{content = {isAward and 'Award' or 'Place'}, css = {['min-width'] = '80px'}})

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

---@return WidgetTableRow[]
function BasePrizePool:_buildRows()
	local rows = {}
	local previousPlacement = nil

	for _, placement in ipairs(self.placements) do
		local previousOpponent = {}

		self:applyToggleExpand(previousPlacement, placement, rows)

		local row = TableRow{}
		row:addClass(placement:getBackground())

		self:applyCutAfter(placement, row)

		row:addCell(self:placeOrAwardCell(placement))

		for _, opponent in ipairs(placement.opponents) do
			local previousOfPrizeType = {}
			local prizeCells = Array.map(self.prizes, function (prize)
				local prizeTypeData = self.prizeTypes[prize.type]
				local reward = opponent.prizeRewards[prize.id] or placement.prizeRewards[prize.id]

				local cell = reward and prizeTypeData.rowDisplay(prize.data, reward) or TableCell{}

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
				local lastInColumn = previousOpponent[columnIndex]

				---@cast prizeCell -nil
				if Table.isEmpty(prizeCell.content) then
					prizeCell = BasePrizePool._emptyCell()
				end

				if lastInColumn and Table.deepEquals(lastInColumn.content, prizeCell.content) then
					lastInColumn.rowSpan = (lastInColumn.rowSpan or 1) + 1
				else
					previousOpponent[columnIndex] = prizeCell
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
		end

		table.insert(rows, row)

		previousPlacement = placement
	end

	return rows
end

---@param placement BasePlacement
function BasePrizePool:placeOrAwardCell(placement)
	error('Function placeOrAwardCell needs to be implemented by a child class of "Module:PrizePool/Base"')
end

---@param placement BasePlacement
---@param row WidgetTableRow
function BasePrizePool:applyCutAfter(placement, row)
	error('Function applyCutAfter needs to be implemented by a child class of "Module:PrizePool/Base"')
end

---@param placement BasePlacement?
---@param nextPlacement BasePlacement
---@param row WidgetTableRow
function BasePrizePool:applyToggleExpand(placement, nextPlacement, row)
	error('Function applyToggleExpand needs to be implemented by a child class of "Module:PrizePool/Base"')
end

---@return string
function BasePrizePool:_getPrizeSummaryText()
	local tba = Abbreviation.make('TBA', 'To Be Announced')
	local tournamentCurrency = Variables.varDefault('tournament_currency')
	local baseMoneyRaw = Variables.varDefault('tournament_prizepool' .. BASE_CURRENCY:lower(), tba)
	local baseMoneyDisplay = Currency.display(BASE_CURRENCY, baseMoneyRaw, {formatValue = true})

	local displayText = {baseMoneyDisplay}

	if tournamentCurrency and tournamentCurrency:upper() ~= BASE_CURRENCY then
		local localMoneyRaw = Variables.varDefault('tournament_prizepoollocal', tba)
		local localMoneyDisplay = Currency.display(tournamentCurrency, localMoneyRaw, {formatValue = true})

		table.insert(displayText, 1, localMoneyDisplay)
		table.insert(displayText, 2,' (≃ ')
		table.insert(displayText, ')')
	end

	table.insert(displayText, ' are spread among the participants as seen below:')
	table.insert(displayText, '<br>')

	return table.concat(displayText)
end

---@return string?
function BasePrizePool:_currencyExchangeInfo()
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

		wrapper:wikitext('<i>(')
		wrapper:wikitext('Converted ' .. currencyText .. ' prizes are ')
		wrapper:wikitext('based on the ' .. exchangeProvider ..' on ' .. exchangeDateText .. ': ')
		wrapper:wikitext(table.concat(Array.map(Array.filter(self.prizes, function (prize)
			return BasePrizePool.prizeTypes[prize.type].convertToBaseCurrency ~= nil
		end), BasePrizePool._CurrencyConvertionText), ', '))
		wrapper:wikitext(')</i>')

		return tostring(wrapper)
	end
end

---@param prize BasePrizePoolPrize
---@return string
function BasePrizePool._CurrencyConvertionText(prize)
	local exchangeRate = BasePrizePool.prizeTypes[PRIZE_TYPE_LOCAL_CURRENCY].convertToBaseCurrency(
		prize.data, 1, BasePrizePool._getTournamentDate()
	)

	return Currency.display(prize.data.currency, 1) .. ' ≃ ' ..
		Currency.display(BASE_CURRENCY, exchangeRate, {formatValue = true, formatPrecision = EXCHANGE_SUMMARY_PRECISION})
end

--- Returns true if this PrizePool has a Base Currency money reward.
-- This is true if any placement has a Base Currency input,
-- or if there is a money reward in another currency whilst currency conversion is active
---@return boolean
function BasePrizePool:_hasBaseCurrency()
	return (Array.any(self.placements, function (placement)
		return placement.hasBaseCurrency or placement.hasPercentage
	end)) or (self.options.autoExchange and Array.any(self.prizes, function (prize)
		return prize.type == PRIZE_TYPE_LOCAL_CURRENCY
	end))
end

--- Creates an empty table cell
---@return WidgetTableCell
function BasePrizePool._emptyCell()
	return TableCell{content = {DASH}}
end

--- Remove all non-numeric characters from an input and changes it to a number.
-- Most commonly used on money inputs, as they often contain , or .
---@param input number|string
---@return number?
function BasePrizePool._parseInteger(input)
	if type(input) == 'number' then
		return input
	elseif type(input) == 'string' then
		return tonumber((input:gsub('[^%d.]', '')))
	end
end

--- Asserts that an Opponent Struct is valid and has a valid type
function BasePrizePool:assertOpponentStructType(typeStruct)
	if not typeStruct then
		error('Please provide a type!')
	elseif type(typeStruct) ~= 'table' or not typeStruct.type then
		error('Could not parse type!')
	elseif not Opponent.isType(typeStruct.type) then
		error('Not a valid type!')
	end
end

--- Fetches the LPDB object of a tournament
---@param pageName string
---@return tournament
function BasePrizePool._getTournamentInfo(pageName)
	return mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. pageName .. ']]',
		limit = 1,
	})[1]
end

--- Returns the default date based on wiki-variables set in the Infobox League
---@return string
function BasePrizePool._getTournamentDate()
	return Variables.varDefault('tournament_enddate', TODAY)
end

---@return self
function BasePrizePool:storeData()
	local prizePoolIndex = (tonumber(Variables.varDefault('prizepool_index')) or 0) + 1
	Variables.varDefine('prizepool_index', prizePoolIndex)

	local lpdbTournamentData = {
		tournament = Variables.varDefault('tournament_name'),
		parent = Variables.varDefault('tournament_parent'),
		series = Variables.varDefault('tournament_series'),
		shortname = Variables.varDefault('tournament_tickername'),
		startdate = Variables.varDefault('tournament_startdate'),
		mode = Variables.varDefault('tournament_mode'),
		type = Variables.varDefault('tournament_type'),
		liquipediatier = Variables.varDefault('tournament_liquipediatier'),
		liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
		publishertier = Variables.varDefault('tournament_publishertier'),
		icon = Variables.varDefault('tournament_icon'),
		icondark = Variables.varDefault('tournament_icondark'),
		game = Variables.varDefault('tournament_game'),
		prizepoolindex = prizePoolIndex,
	}

	local lpdbData = {}
	for _, placement in ipairs(self.placements) do
		local lpdbEntries = placement:_getLpdbData(prizePoolIndex, self.options.lpdbPrefix)

		lpdbEntries = Array.map(lpdbEntries, function(lpdbEntry)
			return Table.merge(
				lpdbTournamentData,
				{
					lastvsdata = {},
					opponentplayers = {},
					players = {},
					extradata = {},
				},
				lpdbEntry
			)
		end)

		Array.extendWith(lpdbData, lpdbEntries)
	end

	for _, lpdbEntry in ipairs(lpdbData) do
		lpdbEntry = Json.stringifySubTables(lpdbEntry)
		local objectName = Table.extract(lpdbEntry, 'objectName')

		if self.options.storeLpdb then
			mw.ext.LiquipediaDB.lpdb_placement(objectName, lpdbEntry)
		end

		Variables.varDefine(objectName .. '_placementdate', lpdbEntry.date)
	end

	if self.options.storeLpdb then
		pageVars:set('placementRecords.' .. prizePoolIndex, Json.stringify(lpdbData))
	end

	return self
end

--- Set the WidgetInjector.
---@param widgetInjector WidgetInjector An instance of a class that implements the WidgetInjector interface
---@return self
function BasePrizePool:setWidgetInjector(widgetInjector)
	assert(widgetInjector:is_a(WidgetInjector), 'setWidgetInjector: Not a Widget Injector')
	self._widgetInjector = widgetInjector
	return self
end

--- Set the LpdbInjector.
---@param lpdbInjector LpdbInjector An instance of a class that implements the LpdbInjector interface
---@return self
function BasePrizePool:setLpdbInjector(lpdbInjector)
	assert(lpdbInjector:is_a(LpdbInjector), 'setLpdbInjector: Not an LPDB Injector')
	self._lpdbInjector = lpdbInjector
	return self
end

return BasePrizePool
