---
-- @Liquipedia
-- page=Module:PrizePool/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')
local Variables = Lua.import('Module:Variables')

local Currency = Lua.import('Module:Currency')
local LpdbInjector = Lua.import('Module:Lpdb/Injector')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local TableCell = TableWidgets.Cell
local TableCellHeader = TableWidgets.CellHeader
local TableRow = TableWidgets.Row
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local Hr = HtmlWidgets.Hr
local LabeledChevronToggle = Lua.import('Module:Widget/GeneralCollapsible/LabeledChevronToggle')
local SwitchPill = Lua.import('Module:Widget/ContentSwitch/Pill')
local WidgetUtil = Lua.import('Module:Widget/Util')

local pageVars = PageVariableNamespace('PrizePool')

--- @class BasePrizePool
--- @operator call(...): BasePrizePool
--- @field options table
--- @field _lpdbInjector LpdbInjector?
local BasePrizePool = Class.new(function(self, ...) self:init(...) end)

---@class BasePrizePoolPrize
---@field id string
---@field type string
---@field index integer
---@field data table

local LANG = mw.language.getContentLanguage()
local DASH = '&#045;'
local NON_BREAKING_SPACE = '&nbsp;'
local BASE_CURRENCY = 'USD'
local EXCHANGE_SUMMARY_PRECISION = 5

local PRIZE_TYPE_BASE_CURRENCY = 'BASE_CURRENCY'
local PRIZE_TYPE_LOCAL_CURRENCY = 'LOCAL_CURRENCY'
local PRIZE_TYPE_PLAYER_SHARE = 'PLAYER_SHARE'
local PRIZE_TYPE_CLUB_SHARE = 'CLUB_SHARE'
local PRIZE_TYPE_QUALIFIES = 'QUALIFIES'
local PRIZE_TYPE_POINTS = 'POINTS'
local PRIZE_TYPE_PERCENTAGE = 'PERCENT'
local PRIZE_TYPE_FREETEXT = 'FREETEXT'

-- Alignment for the fixed (non-prize) columns; prize columns carry `align` on their prize type.
local PLACE_COLUMN_ALIGN = 'center'
local OPPONENT_COLUMN_ALIGN = 'left'

BasePrizePool.config = {
	showBaseCurrency = {
		default = false
	},
	playerShare = {
		default = false,
		read = function(args)
			return Logic.readBoolOrNil(args.playershare)
		end
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
			return MathUtil.toInteger(args.cutafter)
		end
	},
	hideafter = {
		default = math.huge,
		read = function(args)
			local hideAfter = MathUtil.toInteger(args.hideafter)
			local cutAfter = MathUtil.toInteger(args.cutafter) or 4
			if not hideAfter then
				return
			end
			return math.max(cutAfter, hideAfter)
		end
	},
	storeLpdb = {
		default = true,
		read = function(args)
			return Logic.nilOr(
				Logic.readBoolOrNil(args.storelpdb),
				Lpdb.isStorageEnabled()
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
		align = 'right',

		headerDisplay = function (data)
			local currencyText = Currency.display(BASE_CURRENCY)
			return TableCellHeader{children = {currencyText}}
		end,

		row = BASE_CURRENCY:lower() .. 'prize',
		rowParse = function (placement, input, context, index)
			return BasePrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{children = {
					Currency.display(BASE_CURRENCY, data,
						{formatValue = true, formatPrecision = headerData.roundPrecision, displayCurrencyCode = false})
				}}
			end
		end,
	},
	[PRIZE_TYPE_LOCAL_CURRENCY] = {
		sortOrder = 20,
		align = 'right',

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
			return TableCellHeader{children = {Currency.display(data.currency)}}
		end,

		row = 'localprize',
		rowParse = function (placement, input, context, index)
			return BasePrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{children = {
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
		align = 'right',

		header = 'percentage',
		headerParse = function (prizePool, input, context, index)
			assert(index == 1, 'Percentage only supports index 1')
			return {title = 'Percentage'}
		end,
		headerDisplay = function (data)
			return TableCellHeader{children = {data.title}}
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
				return TableCell{children = {data .. '%'}}
			end
		end,
	},
	[PRIZE_TYPE_QUALIFIES] = {
		sortOrder = 50,
		align = 'left',

		header = 'qualifies',
		headerParse = function (prizePool, input, context, index)
			-- Automatically retrieve information from the Tournament
			local tournamentData = Tournament.getTournament(input) or {}
			local prefix = 'qualifies' .. index
			return {
				link = tournamentData.pageName or input:gsub(' ', '_'),
				title = Logic.emptyOr(
					context[prefix .. 'name'],
					tournamentData.displayName,
					input:gsub('_', ' '):gsub('/', ' ')
				),
				icon = tournamentData.icon or context[prefix .. 'icon'],
				iconDark = tournamentData.iconDark or context[prefix .. 'icondark']
			}
		end,
		headerDisplay = function (data)
			return TableCellHeader{children = {'Qualifies To'}}
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

			return TableCell{children = {Div{children = content}}}
		end,

		mergeDisplayColumns = true,
	},
	[PRIZE_TYPE_POINTS] = {
		sortOrder = 40,
		align = 'right',

		header = 'points',
		headerParse = function (prizePool, input, context, index)
			local pointsData = Table.copy(Lua.import('Module:Points/data', {loadData = true})[input] or {})
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
					text = Abbreviation.make{text = data.title, title = data.titleLong}
				elseif String.isNotEmpty(data.title) then
					text = data.title
				end

				if String.isNotEmpty(data.link) then
					text = '[[' .. data.link .. '|' .. text .. ']]'
				end

				table.insert(headerDisplay, text)
			end

			return TableCellHeader{children = headerDisplay}
		end,

		row = 'points',
		rowParse = function (placement, input, context, index)
			return BasePrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{children = {LANG:formatNum(data)}}
			end
		end,
	},
	[PRIZE_TYPE_PLAYER_SHARE] = {
		sortOrder = 22,
		align = 'right',

		headerDisplay = function (data)
			return TableCellHeader{children = {data.title or 'Player Prize'}}
		end,

		--- The player share is a single pool-input-currency value; the per-currency
		--- PLAYER_SHARE columns are derived from it later in _setSharesFromPlayerShare.
		row = 'playershare',
		rowParse = function (placement, input, context, index)
			return BasePrizePool._parseInteger(input)
		end,

		rowDisplay = function (headerData, data)
			if Logic.isNumeric(data) then
				return TableCell{children = {
					Currency.display(headerData.currency, data,
						{formatValue = true, formatPrecision = headerData.roundPrecision, displayCurrencyCode = false})
				}}
			end
		end,
	},
	[PRIZE_TYPE_CLUB_SHARE] = {
		sortOrder = 24,
		align = 'right',

		headerDisplay = function (data)
			return TableCellHeader{children = {data.title or 'Club Reward'}}
		end,

		rowDisplay = function (headerData, data)
			if Logic.isNumeric(data) then
				return TableCell{children = {
					Currency.display(headerData.currency, data,
						{formatValue = true, formatPrecision = headerData.roundPrecision, displayCurrencyCode = false})
				}}
			end
		end,
	},
	[PRIZE_TYPE_FREETEXT] = {
		sortOrder = 60,
		align = 'left',

		header = 'freetext',
		headerParse = function (prizePool, input, context, index)
			return {title = input}
		end,
		headerDisplay = function (data)
			return TableCellHeader{children = {data.title}}
		end,

		row = 'freetext',
		rowParse = function (placement, input, context, index)
			return input
		end,
		rowDisplay = function (headerData, data)
			if String.isNotEmpty(data) then
				return TableCell{children = {data}}
			end
		end,
	}
}

---@param args table
---@return self
function BasePrizePool:init(args)
	self.args = self:_parseArgs(args)

	self.pagename = mw.title.getCurrentTitle().text
	self.date = DateExt.getContextualDateOrNow()
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

		if self.options.playerShare then
			self:_buildShareColumns()
		end
	end

	table.sort(self.prizes, BasePrizePool._comparePrizes)

	return self
end

--- Adds a PLAYER_SHARE and CLUB_SHARE prize for USD and the pool's input currency, and
--- derives each opponent's player/club amounts. Player share is a single-currency input, so
--- shares are only derived for that input currency (the first local currency) and USD; any
--- further local currencies are intentionally not split. Requires a player share input.
---@protected
function BasePrizePool:_buildShareColumns()
	-- Currency order is built explicitly (USD-first) because self.prizes is not yet
	-- sorted at this point in create(), so _getCurrencies() would not be USD-first.
	local localPrizes = Array.filter(self.prizes, function(prize)
		return prize.type == PRIZE_TYPE_LOCAL_CURRENCY
	end)
	Array.sortInPlaceBy(localPrizes, function(prize) return prize.index end)
	local inputPrize = localPrizes[1]

	local currencyEntries = WidgetUtil.collect(
		{code = BASE_CURRENCY, totalKey = PRIZE_TYPE_BASE_CURRENCY .. 1},
		inputPrize and {code = inputPrize.data.currency, totalKey = inputPrize.id} or nil
	)

	local inputCode = inputPrize and inputPrize.data.currency or BASE_CURRENCY
	local localData = inputPrize and inputPrize.data or nil
	local roundPrecision = self.options.currencyRoundPrecision

	Array.forEach(currencyEntries, function(entry, shareIndex)
		self:addPrize(PRIZE_TYPE_PLAYER_SHARE, shareIndex,
			{currency = entry.code, roundPrecision = roundPrecision})
		self:addPrize(PRIZE_TYPE_CLUB_SHARE, shareIndex,
			{currency = entry.code, roundPrecision = roundPrecision, title = Logic.emptyOr(self.args.clubshare)})
	end)

	local plan = Array.map(currencyEntries, function(entry, shareIndex)
		return {shareIndex = shareIndex, code = entry.code, totalKey = entry.totalKey}
	end)

	Array.forEach(self.placements, function(placement)
		placement:_setSharesFromPlayerShare(plan, inputCode, localData)
	end)
end

---@protected
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
---@return Widget
function BasePrizePool:build(isAward)
	local prizePoolTable = self:_buildTable(isAward)

	if self.options.storeLpdb then
		self:storeData()
	end

	if not (self.options.exchangeInfo or self.adjacentContent or self:_shouldDisplayPrizeSummary()) then
		return prizePoolTable
	end

	return Div{classes = {'prizepool-section-wrapper'}, children = WidgetUtil.collect(
		self:_shouldDisplayPrizeSummary() and Span{children = {self:_getPrizeSummaryText()}} or nil,
		Div{
			classes = {'prizepool-section-tables'},
			children = WidgetUtil.collect(prizePoolTable, self.adjacentContent)
		},
		self.options.exchangeInfo and self:_currencyExchangeInfo() or nil
	)}
end

---@param prize BasePrizePoolPrize
---@return string?
function BasePrizePool:_prizeCurrencyCode(prize)
	if prize.type == PRIZE_TYPE_BASE_CURRENCY then
		return BASE_CURRENCY
	elseif prize.type == PRIZE_TYPE_LOCAL_CURRENCY
		or prize.type == PRIZE_TYPE_PLAYER_SHARE
		or prize.type == PRIZE_TYPE_CLUB_SHARE then
		return prize.data.currency
	end
	return nil
end

---Ordered, distinct currency codes used by the money columns (USD first).
---@return string[]
function BasePrizePool:_getCurrencies()
	local currencies = {}
	local seen = {}
	for _, prize in ipairs(self.prizes) do
		local code = self:_prizeCurrencyCode(prize)
		if code and not seen[code] then
			seen[code] = true
			table.insert(currencies, code)
		end
	end
	return currencies
end

---@param cell Widget
---@param prize BasePrizePoolPrize
function BasePrizePool:_tagCurrencyColumn(cell, prize)
	if not self.currencyToggleIndices then
		return
	end
	local code = self:_prizeCurrencyCode(prize)
	local index = code and self.currencyToggleIndices[code]
	if not index then
		return
	end
	cell.props.attributes = cell.props.attributes or {}
	cell.props.attributes['data-toggle-area-content'] = index
end

---@param isAward boolean?
---@return Widget
function BasePrizePool:_buildTable(isAward)
	local currencies = self:_getCurrencies()
	self.currencyToggleIndices = nil
	if #currencies >= 2 then
		self.currencyToggleIndices = Table.map(currencies, function(index, code) return code, index end)
	end

	local bodyRows = self:_buildRows()
	local hasCutRows = Array.any(self.placements, function(placement)
		return not self:applyHideAfter(placement) and self:applyCutAfter(placement)
	end)
	local toggle = hasCutRows and self:_collapseToggle() or nil

	local prizePoolTable = TableWidgets.Table{
		classes = WidgetUtil.collect(
			'prizepool-table-wrapper',
			toggle and 'general-collapsible' or nil,
			toggle and 'collapsed' or nil
		),
		tableClasses = {
			'prizepooltable',
			'prizepooltable-' .. (isAward and 'award' or 'placement'),
		},
		footer = toggle,
		children = {
			TableWidgets.TableHeader{children = {self:_buildHeader(isAward)}},
			TableWidgets.TableBody{children = bodyRows},
		},
	}

	if #currencies < 2 then
		return prizePoolTable
	end

	-- Default to the first local (non-base) currency; fall back to 1 if somehow all are USD.
	local defaultActive = math.max(Array.indexOf(currencies, function(code) return code ~= BASE_CURRENCY end), 1)

	local switchGroupId = (tonumber(Variables.varDefault('prizePoolCurrencySwitchGroupId')) or 0) + 1
	Variables.varDefine('prizePoolCurrencySwitchGroupId', switchGroupId)

	return Div{
		classes = {'prizepool-currency-switch', 'toggle-area', 'toggle-area-' .. defaultActive},
		attributes = {['data-toggle-area'] = defaultActive},
		children = {
			SwitchPill{
				switchGroup = 'prize-pool-currency-' .. switchGroupId,
				storeValue = false,
				defaultActive = defaultActive,
				size = 'extrasmall',
				variant = 'generic',
				tabs = Array.map(currencies, function(code)
					return {label = Currency.display(code), value = code:lower()}
				end),
			},
			prizePoolTable,
		},
	}
end

---@return Renderable?
function BasePrizePool:_collapseToggle()
	local collapseText = self:_collapseText()
	if not collapseText then
		return nil
	end
	return Div{
		classes = {'prizepooltable-toggle'},
		attributes = {['data-collapsible-click-region'] = 'true'},
		children = LabeledChevronToggle{
			expandText = collapseText.opentext,
			collapseText = collapseText.closetext,
		},
	}
end

---@param isAward boolean?
---@return Renderable
function BasePrizePool:_buildHeader(isAward)
	local children = {
		TableCellHeader{children = {isAward and 'Award' or 'Place'}, align = PLACE_COLUMN_ALIGN},
		TableCellHeader{children = {'Participant'}, classes = {'prizepooltable-col-team'}, align = OPPONENT_COLUMN_ALIGN},
	}

	local previousOfType = {}
	for _, prize in ipairs(self.prizes) do
		local prizeTypeData = self.prizeTypes[prize.type]
		if not prizeTypeData.mergeDisplayColumns or not previousOfType[prize.type] then
			local cell = prizeTypeData.headerDisplay(prize.data)
			cell.props.align = cell.props.align or prizeTypeData.align
			self:_tagCurrencyColumn(cell, prize)
			table.insert(children, cell)
			previousOfType[prize.type] = cell
		end
	end

	return TableRow{classes = {'prizepooltable-header'}, children = children}
end

---@return Renderable[]
function BasePrizePool:_buildRows()
	local rows = {}

	for _, placement in ipairs(self.placements) do
		if self:applyHideAfter(placement) then
			break
		end

		local opponents = placement.opponents
		local placeCell = self:placeOrAwardCell(placement)
		local backgroundClass = placement:getBackground()

		-- Build the prize-cell matrix: prizeMatrix[opponentIndex] = {cell, …} in display-column order.
		local prizeMatrix = Array.map(opponents, function(opponent)
			return self:_opponentPrizeCells(placement, opponent)
		end)

		-- Vertically merge consecutive-equal prize cells per column: the first cell of
		-- each run spans the run, the rest are dropped (tracked by cell identity).
		local numCols = prizeMatrix[1] and #prizeMatrix[1] or 0
		local omittedCells = {}
		for col = 1, numCols do
			local columnCells = Array.map(prizeMatrix, function(row) return row[col] end)
			local runs = Array.groupAdjacentBy(columnCells, function(cell)
				return cell.props.children
			end, Table.deepEquals)
			Array.forEach(runs, function(run)
				if #run <= 1 then
					return
				end
				run[1].props.rowspan = #run
				Array.forEach(Array.sub(run, 2), function(cell)
					omittedCells[cell] = true
				end)
			end)
		end

		local isCut = self:applyCutAfter(placement)
		Array.forEach(opponents, function(opponent, opponentIndex)
			local opponentCell = TableCell{
				children = {OpponentDisplay.BlockOpponent{
					opponent = opponent.opponentData,
					showPlayerTeam = true,
				}},
				classes = {'prizepooltable-col-team'},
				align = OPPONENT_COLUMN_ALIGN,
				nowrap = false,
			}
			local prizeCells = Array.filter(prizeMatrix[opponentIndex], function(cell)
				return not omittedCells[cell]
			end)

			table.insert(rows, TableRow{
				children = WidgetUtil.collect(
					opponentIndex == 1 and placeCell or nil,
					opponentCell,
					prizeCells
				),
				classes = WidgetUtil.collect(backgroundClass, isCut and 'ppt-hide-on-collapse' or nil),
			})
		end)
	end

	return rows
end

---@private
---@param placement BasePlacement
---@param opponent BasePlacementOpponent
---@return Renderable[]
function BasePrizePool:_opponentPrizeCells(placement, opponent)
	local previousOfPrizeType = {}
	local prizeCells = Array.map(self.prizes, function(prize)
		local prizeTypeData = self.prizeTypes[prize.type]
		local reward = opponent.prizeRewards[prize.id] or placement.prizeRewards[prize.id]
		local cell = reward and prizeTypeData.rowDisplay(prize.data, reward) or TableCell{}
		cell.props.align = cell.props.align or prizeTypeData.align
		self:_tagCurrencyColumn(cell, prize)

		local lastCellOfType = previousOfPrizeType[prize.type]
		if lastCellOfType and prizeTypeData.mergeDisplayColumns then
			if Logic.isNotEmpty(lastCellOfType.props.children) and Logic.isNotEmpty(cell.props.children) then
				table.insert(lastCellOfType.props.children, Hr{css = {width = '100%'}})
			end
			Array.extendWith(lastCellOfType.props.children, cell.props.children)
			return nil
		end

		previousOfPrizeType[prize.type] = cell
		return cell
	end)

	return Array.map(prizeCells, function(cell)
		if Logic.isNotEmpty(cell.props.children) then
			return cell
		end
		-- Preserve tagging attributes (e.g. the currency toggle index) so empty cells hide
		-- alongside their column; a fresh empty cell would drop them and leak a phantom column.
		local emptyCell = BasePrizePool._emptyCell(cell.props.align)
		emptyCell.props.attributes = cell.props.attributes
		return emptyCell
	end)
end

---@protected
---@param placement BasePlacement
function BasePrizePool:placeOrAwardCell(placement)
	error('Function placeOrAwardCell needs to be implemented by a child class of "Module:PrizePool/Base"')
end

---@protected
---@param placement BasePlacement
---@return boolean
function BasePrizePool:applyHideAfter(placement)
	return false
end

--- Whether a placement's rows are hidden behind the collapse toggle.
--- Child classes override this; the default keeps every row visible.
---@protected
---@param placement BasePlacement
---@return boolean
function BasePrizePool:applyCutAfter(placement)
	return false
end

---Open/close labels for the collapse toggle. Child classes override.
---@protected
---@return {opentext: string, closetext: string}?
function BasePrizePool:_collapseText()
	return nil
end

---@return string
function BasePrizePool:_getPrizeSummaryText()
	local tba = Abbreviation.make{text = 'TBA', title = 'To Be Announced'}
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
		local exchangeProvider = Abbreviation.make{text = 'exchange rate',
			title = Variables.varDefault('tournament_currency_text')}

		if not exchangeProvider then
			return
		end

		-- The exchange date display should not be in the future, as the extension uses current date for those.
		local exchangeDateText = DateExt.formatTimestamp(
			'M j, Y', math.min(DateExt.getCurrentTimestamp(), DateExt.readTimestamp(self.date))
		)

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
		prize.data, 1, DateExt.getContextualDateOrNow()
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
---@param align ('left'|'right'|'center')?
---@return Renderable
function BasePrizePool._emptyCell(align)
	return TableCell{children = {DASH}, align = align}
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

	if self.options.storeLpdb then
		pageVars:set('placementRecords.' .. prizePoolIndex, Json.stringify(lpdbData))
	end

	for _, lpdbEntry in ipairs(lpdbData) do
		lpdbEntry = Json.stringifySubTables(lpdbEntry)
		local objectName = Table.extract(lpdbEntry, 'objectName')

		if self.options.storeLpdb then
			mw.ext.LiquipediaDB.lpdb_placement(objectName, lpdbEntry)
		end

		Variables.varDefine(objectName .. '_placementdate', lpdbEntry.date)
	end

	return self
end

--- Set the LpdbInjector.
---@param lpdbInjector LpdbInjector An instance of a class that implements the LpdbInjector interface
---@return self
function BasePrizePool:setLpdbInjector(lpdbInjector)
	assert(Class.instanceOf(lpdbInjector, LpdbInjector), 'setLpdbInjector: Not an LPDB Injector')
	self._lpdbInjector = lpdbInjector
	return self
end

return BasePrizePool
