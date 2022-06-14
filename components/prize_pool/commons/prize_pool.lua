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
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local WidgetInjector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
-- local LpdbInjector = Lua.import('Module...', {requireDevIfEnabled = true})

local PrizePool = Class.new(function(self, ...) self:init(...) end)

local TODAY = os.date('%Y-%m-%d')

-- TODO: Extract Enum handling to its own Module
local prizeTypes = Table.map({
	'USD', 'LOCAL_CURRENCY', 'POINTS', 'QUALIFIES', 'FREETEXT'
}, function(value, name) return name, value end)

local specialDataTypes = Table.map({
	'LASTVS', 'GROUPSCORE', 'LASTVSSCORE'
}, function(value, name) return name, value end)

local prizeData = {
	[prizeTypes.USD] = {
		row = 'usdprize',
		rowParse = function (prizePool, input, context, index)
			prizePool.hasUSD = true
			return PrizePool._parseInteger(input)
		end
	},
	[prizeTypes.LOCAL_CURRENCY] = {
		header = 'localcurrency',
		headerParse = function (prizePool, input, context, index)
			return {currency = string.upper(input)}
		end,
		row = 'localprize',
		rowParse = function (prizePool, input, context, index)
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

			-- Manual override
			local prefix = 'qualifies' .. index
			data.title = context[prefix .. 'name'] or data.title

			return data
		end,
		row = 'qualified',
		rowParse = function (prizePool, input, context, index)
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
		rowParse = function (prizePool, input, context, index)
			return PrizePool._parseInteger(input)
		end
	},
	[prizeTypes.FREETEXT] = {
		header = 'freetext',
		headerParse = function (prizePool, input, context, index)
			return {title = input}
		end,
		row = 'freetext',
		rowParse = function (prizePool, input, context, index)
			return input
		end
	},
}

local specialData = {
	[specialDataTypes.GROUPSCORE] = {
		field = 'wdl',
		parse = function (prizePool, input, context)
			return input
		end
	},
	[specialDataTypes.LASTVS] = {
		field = 'lastvs',
		parse = function (prizePool, input, context)
			return prizePool:_parseOpponentArgs(input, context.date)
		end
	},
	[specialDataTypes.LASTVSSCORE] = {
		field = 'lastvsscore',
		parse = function (prizePool, input, context)
			local scores = Table.mapValues(mw.text.split(input, '-'), tonumber)
			return {score = scores[1], vsscore = scores[2]}
		end
	},
}

function PrizePool:init(args)
	self.args = args
	self.pagename = mw.title.getCurrentTitle().text
	self.args.type = Json.parseIfString(self.args.type)
	self.date = args.date or Variables.varDefaultMulti('tournament_enddate', 'tournament_edate', 'edate', TODAY)
	if args.opponentLibrary then
		Opponent = require('Module:'.. args.opponentLibrary)
	end

	if not self.args.type then
		return error('Please provide a type!')
	elseif type(self.args.type) ~= 'table' or not self.args.type.type then
		return error('Could not parse type!')
	elseif not Opponent.isType(self.args.type.type) then
		return error('Not a valid type!')
	end

	self.opponentType = self.args.type.type

	return self
end

function PrizePool:readInput(args)
	self.options = self:_readStandardOptions(args)
	self.prizes = self:_readPrizes(args)
	self.placements = self:_readPlacements(args)

	if self:_hasUsdPrizePool() then
		self:setOption('showUSD', true)
		self:addPrize('USD', 1)
	end

	return self
end

function PrizePool:create()
	-- TODO
	mw.logObject(self)
	return ''
end

function PrizePool:_readStandardOptions(args)
	local options = {}

	self:setOption('autoUSD', Logic.nilOr(Logic.readBoolOrNil(args.autousd), true), options)
	self:setOption('showUSD', false, options)
	self:setOption('prizeSummary', Logic.nilOr(Logic.readBoolOrNil(args.prizesummary), true), options)
	self:setOption('exchangeInfo', Logic.nilOr(Logic.readBoolOrNil(args.exchangeinfo), true), options)
	self:setOption('storeSmw', Logic.nilOr(Logic.readBoolOrNil(args.storesmw), true), options)
	self:setOption('storeLpdb', Logic.nilOr(Logic.readBoolOrNil(args.storelpdb), true), options)

	return options
end

function PrizePool:_readPrizes(args)
	local prizes = {}

	for prizeEnum in pairs(prizeTypes) do
		local prizeDatum = prizeData[prizeTypes[prizeEnum]]
		local fieldName = prizeDatum.header
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, prizeValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				local data = prizeDatum.headerParse(self, prizeValue, args, index)
				self:addPrize(prizeEnum, index, data, prizes)
			end
		end
	end

	return prizes
end

function PrizePool:_readPrizeRewards(args)
	local rewards = {}

	for prizeEnum in pairs(prizeTypes) do
		local prizeDatum = prizeData[prizeTypes[prizeEnum]]
		local fieldName = prizeDatum.row
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, rewardValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				rewards[prizeEnum .. index] = prizeDatum.rowParse(self, rewardValue, args, index)
			end
		end
	end

	return rewards
end

function PrizePool:_readSpecialData(args)
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

function PrizePool:_readPlacements(args)
	local placements = {}

	local currentPlace = 0
	for placementIndex = 1, math.huge do
		local placementInput = Json.parseIfString(args[placementIndex])
		if not placementInput then
			break
		end

		local placement = {}
		-- Parse place, explicit
		if placementInput.place then
			local places = Table.mapValues(mw.text.split(placementInput.place, '-'), tonumber)
			placement.placeStart = places[1]
			placement.placeEnd = places[2] or places[1]
			assert(placement.placeStart and placement.placeEnd, placement.place .. ' is an invalid place (range).')
		end

		-- Parse prizes
		placement.prizes = self:_readPrizeRewards(placementInput)

		-- Parse opponents in the placement
		placement.opponents = {}
		for opponentIndex = 1, math.huge do
			local opponentInput = Json.parseIfString(placementInput[opponentIndex])
			local opponent = {opponentData = {}, prizes = {}, data = {}}
			if not opponentInput then
				-- If given a range of opponents, add them all, even if they're missing from the input
				if not placementInput.place or placement.placeStart + opponentIndex > placement.placeEnd + 1 then
					break
				else
					opponent.opponentData = Opponent.tbd()
				end
			else
				-- Set the date
				if PrizePool.isValidDate(opponentInput.date) then
					opponent.date = opponentInput.date
				else
					opponent.date = self.date
				end

				-- Parse Opponent Data
				opponentInput.type = opponentInput.type or self.opponentType
				opponent.opponentData = self:_parseOpponentArgs(opponentInput, opponent.date)

				-- Parse special prizes for this opponent
				opponent.prizes = self:_readPrizeRewards(opponentInput)

				-- Parse additional data (groupscore, last opponent etc)
				opponent.data = self:_readSpecialData(opponentInput)
			end
			table.insert(placement.opponents, opponent)
		end

		-- Parse place, implicit
		if not placementInput.place then
			placement.placeStart = currentPlace + 1
			placement.placeEnd = currentPlace + #placement.opponents
		end

		assert(placement.placeStart and placement.placeEnd, 'readPlacements: Invalid |place= provided.')
		assert(#placement.opponents > placement.placeEnd - placement.placeStart, 'readPlacements: Too many opponents')
		currentPlace = placement.placeEnd
		table.insert(placements, placement)
	end

	return placements
end

function PrizePool:_parseOpponentArgs(input, date)
	local opponentArgs = Json.parseIfTable(input) or (type(input) == 'table' and input or {input})
	opponentArgs.type = opponentArgs.type or self.opponentType
	opponentArgs.date = date or self.date
	assert(Opponent.isType(opponentArgs.type), 'Invalid type')
	local opponentData = Opponent.readOpponentArgs(opponentArgs) or Opponent.tbd()
	return Opponent.resolve(opponentData, date)
end

function PrizePool:setOption(option, value, list)
	list = list or self.options
	list[option] = value
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

function PrizePool:addPrize(enum, index, data, list)
	assert(prizeTypes[enum], 'addPrize: Not a valid prizeEnum!')
	assert(Logic.isNumeric(index), 'addPrize: Index is not numeric!')
	list = list or self.prizes
	table.insert(list, {id = enum .. index, enum = prizeTypes[enum], index = index, data = data})
	return self
end

function PrizePool:setWidgetInjector(widgetInjector)
	assert(widgetInjector:is_a(WidgetInjector), "setWidgetInjector: Not a WidgetIjector")
	self.widgetInjector = widgetInjector
	return self
end

function PrizePool:setLpdbInjector(lpdbInjector)
	-- TODO: Add type check
	self.lpdbInjector = lpdbInjector
	return self
end

function PrizePool:_hasUsdPrizePool()
	return self.hasUSD or (self.options.autoUSD and Table.any(self.prizes, function (_, prize)
		return prize.enum == prizeTypes.LOCAL_CURRENCY
	end))
end

function PrizePool._parseInteger(input)
	-- Remove all none-numeric characters (such as ,.')
	return tonumber((string.gsub(input, '[^%d.]', '')))
end

function PrizePool._isValidDateFormat(date)
	return string.match(date, '%d%d%d%d-%d%d-%d%d')
end

function PrizePool._getTournamentInfo(pageName)
	return mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. pageName .. ']]',
		limit = 1,
	})[1]
end

return PrizePool
