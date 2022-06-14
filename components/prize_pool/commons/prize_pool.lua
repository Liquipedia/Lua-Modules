---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent') -- Note: This can be overwritten
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local WidgetInjector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local PrizePool = Class.new(function(self, ...) self:init(...) end)
local Placement = Class.new(function(self, ...) self:init(...) end)

local TODAY = os.date('%Y-%m-%d')

-- TODO: Extract Enum handling to its own Module
local prizeTypes = Table.map({
	'USD', 'LOCAL_CURRENCY', 'POINTS', 'QUALIFIES', 'FREETEXT'
}, function(value, name) return name, value end)

local specialDataTypes = Table.map({
	'LASTVS', 'GROUPSCORE', 'LASTVSSCORE'
}, function(value, name) return name, value end)

local config = {
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
	storelpdb = {
		default = true,
	},
}

local prizeData = {
	[prizeTypes.USD] = {
		row = 'usdprize',
		rowParse = function (placement, input, context, index)
			return PrizePool._parseInteger(input)
		end
	},
	[prizeTypes.LOCAL_CURRENCY] = {
		header = 'localcurrency',
		headerParse = function (prizePool, input, context, index)
			return {currency = string.upper(input)}
		end,
		row = 'localprize',
		rowParse = function (placement, input, context, index)
			return PrizePool._parseInteger(input)
		end
	},
	[prizeTypes.QUALIFIES] = {
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
		row = 'qualified',
		rowParse = function (placement, input, context, index)
			return Logic.readBool(input)
		end
	},
	[prizeTypes.POINTS] = {
		header = 'points',
		headerParse = function (prizePool, input, context, index)
			local pointsData = mw.loadData('Module:Points/data')
			return pointsData[input] or {title = 'Points'}
		end,
		row = 'points',
		rowParse = function (placement, input, context, index)
			return PrizePool._parseInteger(input)
		end
	},
	[prizeTypes.FREETEXT] = {
		header = 'freetext',
		headerParse = function (prizePool, input, context, index)
			return {title = input}
		end,
		row = 'freetext',
		rowParse = function (placement, input, context, index)
			return input
		end
	},
}

local specialData = {
	[specialDataTypes.GROUPSCORE] = {
		field = 'wdl',
		parse = function (placement, input, context)
			return input
		end
	},
	[specialDataTypes.LASTVS] = {
		field = 'lastvs',
		parse = function (placement, input, context)
			return placement:_parseOpponentArgs(input, context.date)
		end
	},
	[specialDataTypes.LASTVSSCORE] = {
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
		self:addPrize('USD', 1)
	end

	return self
end

function PrizePool:build()
	-- TODO
	mw.logObject(self)
	return ''
end

function PrizePool:_readConfig(args)
	for name, configData in pairs(config) do
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
	for prizeEnum in pairs(prizeTypes) do
		local prizeDatum = prizeData[prizeTypes[prizeEnum]]
		assert(prizeDatum, 'Error: Missmatch between prizeData and prizeTypes. Is a prizeType missing in prizeData?')
		local fieldName = prizeDatum.header
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, prizeValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				local data = prizeDatum.headerParse(self, prizeValue, args, index)
				self:addPrize(prizeEnum, index, data)
			end
		end
	end

	return self.prizes
end

function PrizePool:_readPlacements(args)
	local currentPlace = 0
	for placementIndex = 1, math.huge do
		if not args[placementIndex] then
			break
		end

		local placementInput = Json.parseIfString(args[placementIndex])
		local placement = Placement(placementInput, currentPlace + 1, self.opponentType)

		currentPlace = placement.placeEnd
		table.insert(self.placements, placement)
	end

	return self.placements
end

function PrizePool:setConfig(option, value)
	self.options[option] = value
	return self
end

function PrizePool:addCustomConfig(name, default, func)
	config[name] = {
		default = default,
		func = func
	}
	return self
end

-- TODO extract parts of this to the future Enum class
local CUSTOM_TYPES_OFFSET = 100
local CUSTOM_TYPES_USED = 0
function PrizePool:addCustomPrizeType(enum, data)
	prizeTypes[enum] = CUSTOM_TYPES_OFFSET + CUSTOM_TYPES_USED
	CUSTOM_TYPES_USED = CUSTOM_TYPES_USED + 1
	prizeData[prizeTypes[enum]] = data
	return self
end

function PrizePool:addPrize(enum, index, data)
	assert(prizeTypes[enum], 'addPrize: Not a valid prizeEnum!')
	assert(Logic.isNumeric(index), 'addPrize: Index is not numeric!')
	table.insert(self.prizes, {id = enum .. index, enum = prizeTypes[enum], index = index, data = data})
	return self
end

function PrizePool:setWidgetInjector(widgetInjector)
	assert(widgetInjector:is_a(WidgetInjector), "setWidgetInjector: Not a WidgetIjector")
	self.widgetInjector = widgetInjector
	return self
end

function PrizePool:setLpdbInjector(lpdbInjector)
	-- TODO: Add type check once interface has been created
	self.lpdbInjector = lpdbInjector
	return self
end

function PrizePool:_hasUsdPrizePool()
	return (Table.any(self.placements, function (_, placement)
		return placement.hasUSD
	end)) or (self.options.autoUSD and Table.any(self.prizes, function (_, prize)
		return prize.enum == prizeTypes.LOCAL_CURRENCY
	end))
end

--
-- Static Functions
--

--- Remove all non-numeric characters from an input and changes it to a number.
-- Most commonly used on money inputs, as they often contain , or .
function PrizePool._parseInteger(input)
	return tonumber((string.gsub(input, '[^%d.]', '')))
end

--- Checks if the input matches the format of a date
function PrizePool._isValidDateFormat(date)
	if String.isEmpty(date) then
		return false
	end
	return string.match(date, '%d%d%d%d-%d%d-%d%d') and true or false
end

--- Checks that an Opponent Struct is valid and has a valid type
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

--- Get the default date based on wiki-variables set in the Infobox League
function PrizePool._getTournamentDate()
	return Variables.varDefaultMulti('tournament_enddate', 'tournament_edate', 'edate', TODAY)
end

---
function Placement:init(args, placeStart, opponentType)
	self.args = self:_parseArgs(args)
	self.date = self.args.date or PrizePool._getTournamentDate()
	self.placeStart = self.args.placeStart
	self.placeEnd = self.args.placeEnd
	self.opponentType = opponentType
	self.opponents = {}
	self.prizes = {}

	-- Parse prizes
	self.prizes = self:_readPrizeRewards(self.args)

	-- Parse opponents
	self.opponents = self:_parseOpponents(self.args)

	-- Implicit place range has been given (|place= is not set)
	-- Use the last known place and set the place range based on the entered number of opponents
	if not self.placeStart and not self.placeEnd then
		self.placeStart = placeStart
		self.placeEnd = placeStart + #self.opponents - 1
	end

	assert(self.placeStart and self.placeEnd, 'readPlacements: Invalid |place= provided.')
	assert(#self.opponents > self.placeEnd - self.placeStart, 'readPlacements: Too many opponents')
end

function Placement:_parseArgs(args)
	local parsedArgs = Table.deepCopy(args)
	-- Explicit place range has been given
	if args.place then
		local places = Table.mapValues(mw.text.split(args.place, '-'), tonumber)
		parsedArgs.placeStart = places[1]
		parsedArgs.placeEnd = places[2] or places[1]
	end
	return parsedArgs
end

--- Parse the input for available rewards of prizes, for instance how much money a team would win.
function Placement:_readPrizeRewards(args)
	local rewards = {}

	for prizeEnum in pairs(prizeTypes) do
		local prizeDatum = prizeData[prizeTypes[prizeEnum]]
		local fieldName = prizeDatum.row
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, rewardValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				if prizeTypes[prizeEnum] == prizeTypes.USD then
					self.hasUSD = true
				end
				rewards[prizeEnum .. index] = prizeDatum.rowParse(self, rewardValue, args, index)
			end
		end
	end

	return rewards
end

function Placement:_readSpecialData(args)
	local data = {}

	for enum in pairs(specialDataTypes) do
		local type = specialData[specialDataTypes[enum]]
		local fieldName = type.field
		if args[fieldName] then
			data[enum] = type.parse(self, args[fieldName], args)
		end
	end

	return data
end

function Placement:_parseOpponents(args)
	-- Parse opponents in the placement
	for opponentIndex = 1, math.huge do
		local opponentInput = Json.parseIfString(args[opponentIndex])
		local opponent = {opponentData = {}, prizes = {}, data = {}}
		if not opponentInput then
			-- If given a range of opponents, add them all, even if they're missing from the input
			if not args.place or self.placeStart + opponentIndex > self.placeEnd + 1 then
				break
			else
				opponent.opponentData = Opponent.tbd()
			end
		else
			-- Set the date
			if not PrizePool._isValidDateFormat(opponentInput.date) then
				opponentInput.date = self.date
			end

			-- Parse Opponent Data
			local typeStruct = Json.parseIfString(opponentInput.type)
			if typeStruct then
				PrizePool._assertOpponentStructType(typeStruct)
				opponentInput.type = typeStruct.type
			else
				opponentInput.type = self.opponentType
			end
			opponent.opponentData = self:_parseOpponentArgs(opponentInput, opponentInput.date)

			-- Parse specific prizes for this opponent
			opponent.prizes = self:_readPrizeRewards(opponentInput)

			-- Parse additional data (groupscore, last opponent etc)
			opponent.data = self:_readSpecialData(opponentInput)

			-- Set date
			opponent.date = opponentInput.date
		end
		table.insert(self.opponents, opponent)
	end
	return self.opponents
end

function Placement:_parseOpponentArgs(input, date)
	-- Allow for lua-table, json-table and just raw string input
	local opponentArgs = Json.parseIfTable(input) or (type(input) == 'table' and input or {input})
	opponentArgs.type = opponentArgs.type or self.opponentType
	assert(Opponent.isType(opponentArgs.type), 'Invalid type')
	local opponentData = Opponent.readOpponentArgs(opponentArgs) or Opponent.tbd()
	return Opponent.resolve(opponentData, date)
end

return PrizePool
