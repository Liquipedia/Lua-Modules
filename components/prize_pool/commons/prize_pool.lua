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
local Opponent = require('Module:Opponent')
local Table = require('Module:Table')

local WidgetInjector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
-- local LpdbInjector = Lua.import('Module...', {requireDevIfEnabled = true})

local PrizePool = Class.new(function(self, ...) self:init(...) end)

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
		rowParse = function (input)
			return tonumber((string.gsub(input, '[^%d.]', '')))
		end
	},
	[prizeTypes.LOCAL_CURRENCY] = {
		header = 'localcurrency',
		headerParse = function (input)
			return {currency = string.upper(input)}
		end,
		row = 'localprize',
		rowParse = function (input)
			return tonumber((string.gsub(input, '[^%d.]', '')))
		end
	},
	[prizeTypes.QUALIFIES] = {
		header = 'qualifies',
		headerParse = function (input)
			-- TODO: Add support for manual and automatic retrevial of additional data
			return {link = input:gsub(' ', '_')}
		end,
		row = 'qualified',
		rowParse = function (input)
			return Logic.readBool(input)
		end
	},
	[prizeTypes.POINTS] = {
		header = 'points',
		headerParse = function (input)
			local pointsData = mw.loadData('Module:Points/data')
			return pointsData[input] or {title = 'Points'}
		end,
		row = 'points',
		rowParse = function (input)
			return tonumber((string.gsub(input, '[^%d.]', '')))
		end
	},
	[prizeTypes.FREETEXT] = {
		header = 'freetext',
		headerParse = function (input)
			return {title = input}
		end,
		row = 'freetext',
		rowParse = function (input)
			return input
		end
	},
}

local specialData = {
	[specialDataTypes.GROUPSCORE] = {
		field = 'wdl',
		parse = function (input)
			return input
		end
	},
	[specialDataTypes.LASTVS] = {
		field = 'lastvs',
		parse = function (input)
			return {} -- TODO Parse properly
		end
	},
	[specialDataTypes.LASTVSSCORE] = {
		field = 'lastvsscore',
		parse = function (input)
			local scores = Table.mapValues(Table.mapValues(mw.text.split(input, '-'), mw.text.trim), tonumber)
			return {score = scores[1], vsscore = scores[2]}
		end
	},
}

function PrizePool:init(args)
	self.args = args
	self.pagename = mw.title.getCurrentTitle().text
	self.args.type = Json.parseIfString(self.args.type)

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
	self.prizes = self:_readPrizes(args, 'header')
	if self.options.showUSD then
		self:addPrize('USD', 1)
	end
	self.placements = self:_readPlacements(args)

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
	self:setOption('showUSD', Logic.nilOr(Logic.readBoolOrNil(args.showusd), true), options) -- TODO: Improve
	self:setOption('prizeSummary', Logic.nilOr(Logic.readBoolOrNil(args.prizesummary), true), options)
	self:setOption('exchangeInfo', Logic.nilOr(Logic.readBoolOrNil(args.exchangeinfo), true), options)
	self:setOption('storeSmw', Logic.nilOr(Logic.readBoolOrNil(args.storesmw), true), options)
	self:setOption('storeLpdb', Logic.nilOr(Logic.readBoolOrNil(args.storelpdb), true), options)

	return options
end

function PrizePool:_readPrizes(args, type)
	-- TODO the return datastructure for row should be different. Split the functions?
	type = type or 'row'
	local prizes = {}

	for prizeEnum in pairs(prizeTypes) do
		local prizeDatum = prizeData[prizeTypes[prizeEnum]]
		local fieldName = prizeDatum[type]
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, prizeValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				local data = prizeDatum[type ..'Parse'](prizeValue)
				self:addPrize(prizeEnum, index, data, prizes)
			end
		end
	end

	return prizes
end

function PrizePool:_readSpecialData(args)
	local data = {}

	for enum in pairs(specialDataTypes) do
		local type = specialData[specialDataTypes[enum]]
		local fieldName = type.field
		if args[fieldName] then
			data[enum] = type.parse(args[fieldName])
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
			local places = Table.mapValues(mw.text.split(placementInput.place, '-'), mw.text.trim)
			places = Table.mapValues(places, tonumber)
			placement.placeStart = places[1]
			placement.placeEnd = places[2] or places[1]
		end

		-- Parse prizes
		placement.prizes = self:_readPrizes(placementInput)

		-- Parse opponents in the placement
		placement.opponents = {}
		for opponentIndex = 1, math.huge do
			local opponentInput = Json.parseIfString(placementInput[opponentIndex])
			if not opponentInput then -- TODO: always iterate until the end placeEnd, if given
				break
			end

			local opponent = {opponentData = {}, prizes = {}, data = {}}

			-- Parse Opponent Data
			-- TODO: Add support to use wiki specific opponent modules
			opponentInput.type = opponentInput.type or self.opponentType
			opponent.opponentData = Opponent.readOpponentArgs(opponentInput) or Opponent.tbd()
			opponent.date = opponentInput.date

			-- Parse special prizes for this opponent
			opponent.prizes = self:_readPrizes(opponentInput)

			-- Parse additional data (groupscore, last opponent etc)
			opponent.data = self:_readSpecialData(opponentInput)

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
	table.insert(list, {id = enum .. index, enum = enum, index = index, data = data})
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

return PrizePool
