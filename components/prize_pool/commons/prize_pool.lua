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
local Currency = require('Module:LocalCurrency')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchPlacement = require('Module:Match/Placement')
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
	storeSmw = {
		default = true,
	},
	storeLpdb = {
		default = true,
	},
	resolveRedirect = {
		default = false,
	}
}

PrizePool.prizeTypes = {
	[PRIZE_TYPE_USD] = {
		sortOrder = 10,

		headerDisplay = function (data)
			local currencyText = {Template.safeExpand(mw.getCurrentFrame(), 'Local currency', {'USD'})}
			return TableCell{content = currencyText}
		end,

		row = 'usdprize',
		rowParse = function (placement, input, context, index)
			return PrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{content = {'$', Currency.formatMoney(data)}}
			end
		end,
	},
	[PRIZE_TYPE_LOCAL_CURRENCY] = {
		sortOrder = 20,

		header = 'localcurrency',
		headerParse = function (prizePool, input, context, index)
			Variables.varDefine('localcurrencysymbol', '')
			Variables.varDefine('localcurrencysymbolafter', '')
			Variables.varDefine('localcurrencycode', '')
			local currencyText = Template.safeExpand(mw.getCurrentFrame(), 'Local currency', {input})

			local symbol, symbolFirst
			if Variables.varDefault('localcurrencysymbol') then
				symbol = Variables.varDefault('localcurrencysymbol')
				symbolFirst = true
			elseif Variables.varDefault('localcurrencysymbolafter') then
				symbol = Variables.varDefault('localcurrencysymbolafter')
				symbolFirst = false
			else
				error(input .. ' could not be parsed as a currency, has it been added to [[Template:Local currency]]?')
			end

			return {
				currency = Variables.varDefault('localcurrencycode'), currencyText = currencyText,
				symbol = symbol, symbolFirst = symbolFirst
			}
		end,
		headerDisplay = function (data)
			return TableCell{content = {data.currencyText}}
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

				return TableCell{content = displayText}
			end
		end,

		convertToUsd = function (headerData, data, date)
			return mw.ext.CurrencyExchange.currencyexchange(data, headerData.currency, BASE_CURRENCY, date)
		end,
	},
	[PRIZE_TYPE_QUALIFIES] = {
		sortOrder = 30,

		header = 'qualifies',
		headerParse = function (prizePool, input, context, index)
			local link = input:gsub(' ', '_')
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

			return TableCell{content = content}
		end,
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

			return TableCell{content = headerDisplay}
		end,

		row = 'points',
		rowParse = function (placement, input, context, index)
			return PrizePool._parseInteger(input)
		end,
		rowDisplay = function (headerData, data)
			if data > 0 then
				return TableCell{content = {LANG:formatNum(data)}}
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
			return TableCell{content = {data.title}}
		end,

		row = 'freetext',
		rowParse = function (placement, input, context, index)
			return input
		end,
		rowDisplay = function (headerData, data)
			if String.isNotEmpty(data) then
				return TableCell{content = {data}}
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

function PrizePool:init(args)
	self.args = self:_parseArgs(args)

	self.pagename = mw.title.getCurrentTitle().text
	self.date = PrizePool._getTournamentDate()
	self.opponentType = self.args.type
	if self.args.opponentLibrary then
		Opponent = require('Module:'.. self.args.opponentLibrary)
	end

	self.options = {}
	self.prizes = {}
	self.placements = {}

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
	local table = WidgetTable{}

	table:addRow(self:_buildHeader())

	for _, row in ipairs(self:_buildRows()) do
		table:addRow(row)
	end

	table:setContext{self._widgetInjector}

	local wrapper = mw.html.create('div')
	for _, node in ipairs(WidgetFactory.work(table, self._widgetInjector)) do
		wrapper:node(node)
	end

	if self.options.storeLpdb then
		self:_storeLpdb()
	end

	return wrapper
end

function PrizePool:_buildHeader()
	local headerRow = TableRow{css = {['font-weight'] = 'bold'}}

	headerRow:addCell(TableCell{content = {'Place'}})

	for _, prize in ipairs(self.prizes) do
		local prizeTypeData = self.prizeTypes[prize.type]
		local cell = prizeTypeData.headerDisplay(prize.data)
		headerRow:addCell(cell)
	end

	if self:_hasPartyType() then
		headerRow:addCell(TableCell{content = {'Player'}})
	end
	headerRow:addCell(TableCell{content = {'Team'}})

	return headerRow
end

function PrizePool:_buildRows()
	local rows = {}

	for _, placement in ipairs(self.placements) do
		local previousRow = {}
		-- TODO Cutoff

		for opponentIndex, opponent in ipairs(placement.opponents) do
			local row = TableRow{}

			row:addClass(placement:getBackground())

			if opponentIndex == 1 then
				local placeCell = TableCell{
					content = {placement:getMedal() or '' , NON_BREAKING_SPACE, placement:displayPlace()},
					css = {['font-weight'] = 'bolder'},
				}
				placeCell.rowSpan = #placement.opponents
				row:addCell(placeCell)
			end

			for prizeIndex, prize in ipairs(self.prizes) do
				local prizeTypeData = self.prizeTypes[prize.type]
				local reward = opponent.prizeRewards[prize.id] or placement.prizeRewards[prize.id]
				local lastInColumn = previousRow[prizeIndex]

				local cell
				if reward then
					cell = prizeTypeData.rowDisplay(prize.data, reward)
				end
				cell = cell or PrizePool._emptyCell()

				if lastInColumn and Table.deepEquals(lastInColumn.content, cell.content) then
					lastInColumn.rowSpan = (lastInColumn.rowSpan or 1) + 1
				else
					previousRow[prizeIndex] = cell
					row:addCell(cell)
				end
			end

			local opponentDisplay = tostring(OpponentDisplay.BlockOpponent{opponent = opponent.opponentData})
			local opponentCss = {['justify-content'] = 'start'}

			local opponentIsParty = Opponent.typeIsParty(opponent.opponentData.type)

			if self:_hasPartyType() then
				if opponentIsParty then
					row:addCell(TableCell{content = {opponentDisplay}, css = opponentCss})
				else
					row:addCell(PrizePool._emptyCell())
				end
			end

			if opponentIsParty then
				if opponent.opponentData.players[1] and opponent.opponentData.players[1].team then
					row:addCell(TableCell{content = {tostring(OpponentDisplay.BlockOpponent{
						opponent = {type = 'team', template = opponent.opponentData.players[1].team}
					})}, css = opponentCss})
				else
					row:addCell(PrizePool._emptyCell())
				end
			else
				row:addCell(TableCell{content = {opponentDisplay}, css = opponentCss})
			end

			table.insert(rows, row)
		end
	end

	return rows
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
	assert(widgetInjector:is_a(WidgetInjector), "setWidgetInjector: Not a WidgetInjector")
	self._widgetInjector = widgetInjector
	return self
end

function PrizePool:setLpdbInjector(lpdbInjector)
	-- TODO: Add type check once interface has been created
	self._lpdbInjector = lpdbInjector
	return self
end

function PrizePool:_storeLpdb()
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
		-- TODO: Add PrizePoolIndex as a field?
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
		local lowerCaseParticipant = mw.ustring.lower(lpdbEntry.participant)
		mw.ext.LiquipediaDB.lpdb_placement('ranking_' .. prizePoolIndex .. '_' .. lowerCaseParticipant, lpdbEntry)
	end

	return self
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

--- Returns true if this prizePool or any opponent entered into the prizepool is of a PartyType
function PrizePool:_hasPartyType()
	local placementHasParty = function (placement)
		return placement.hasPartyType
	end

	return Opponent.typeIsParty(self.opponentType) or Array.any(self.placements, placementHasParty)
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
	return date:match('%d%d%d%d-%d%d-%d%d') and true or false
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

	for prizeType, prizeData in pairs(self.parent.prizeTypes) do
		local fieldName = prizeData.row
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, rewardValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				if prizeType == PRIZE_TYPE_USD then
					self.hasUSD = true
				end
				rewards[prizeType .. index] = prizeData.rowParse(self, rewardValue, args, index)
			end
		end
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
				opponent.opponentData = Opponent.tbd()
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

			if Opponent.typeIsParty(opponent.opponentData.type) then
				self.hasPartyType = true
			end
		end
		return opponent
	end)
end

function Placement:_parseOpponentArgs(input, date)
	-- Allow for lua-table, json-table and just raw string input
	local opponentArgs = Json.parseIfTable(input) or (type(input) == 'table' and input or {input})
	opponentArgs.type = opponentArgs.type or self.parent.opponentType
	assert(Opponent.isType(opponentArgs.type), 'Invalid type')
	local opponentData = Opponent.readOpponentArgs(opponentArgs) or Opponent.tbd()
	return Opponent.resolve(opponentData, date)
end

function Placement:_getLpdbData()
	local entries = {}
	for _, opponent in ipairs(self.opponents) do
		local participant, image, imageDark, players
		local playerCount = 0

		if opponent.opponentData.type == Opponent.team then
			local teamTemplate = mw.ext.TeamTemplate.raw(opponent.opponentData.template)

			participant = teamTemplate and teamTemplate.page or ''
			if self.parent.options.resolveRedirect then
				participant = mw.ext.TeamLiquidIntegration.resolve_redirect(participant)
			end

			image = teamTemplate.image
			imageDark = teamTemplate.imagedark
		elseif opponent.opponentData.type == Opponent.solo then
			participant = Opponent.toName(opponent.opponentData)
			local p1 = opponent.opponentData.players[1]
			players = {p1 = p1.pageName, p1dn = p1.displayName, p1flag = p1.flag, p1team = p1.team}
			playerCount = 1
		else
			participant = Opponent.toName(opponent.opponentData)
		end

		local prizeMoney = tonumber(opponent.prizeRewards[PRIZE_TYPE_USD .. 1] or self.prizeRewards[PRIZE_TYPE_USD .. 1]) or 0
		local lpdbData = {
			image = image,
			imagedark = imageDark,
			date = opponent.date,
			participant = participant,
			participantlink = Opponent.toName(opponent.opponentData),
			participantflag = opponent.opponentData.flag,
			participanttemplate = opponent.opponentData.template,
			players = players,
			placement = self.placeStart .. (self.placeStart ~= self.placeEnd and ('-' .. self.placeEnd) or ''),
			prizemoney = prizeMoney,
			individualprizemoney = (playerCount > 0) and (prizeMoney / playerCount) or 0,
			lastvs = Opponent.toName(opponent.additionalData.LASTVS or {}),
			lastscore = (opponent.additionalData.LASTVSSCORE or {}).score,
			lastvsscore = (opponent.additionalData.LASTVSSCORE or {}).vsscore,
			groupscore = opponent.additionalData.GROUPSCORE,
			extradata = {}

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

			usdReward = usdReward + prizeTypes[prize.type].convertToUsd(prize.data, localMoney, opponent.date)
		end)

		opponent.prizeRewards[PRIZE_TYPE_USD .. 1] = usdReward
	end)
end

function Placement:displayPlace()
	local start = Ordinal._ordinal(self.placeStart)
	if self.placeEnd > self.placeStart then
		return start .. DASH .. Ordinal._ordinal(self.placeEnd)
	end
	return start
end

function Placement:getBackground()
	return PlacementInfo.getBgClass(self.placeStart)
end

function Placement:getMedal()
	local medal = MatchPlacement.MedalIcon{range = {self.placeStart, self.placeEnd}}
	if medal then
		return tostring(medal)
	end
end

return PrizePool
