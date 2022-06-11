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

local prizeData = {
	[prizeTypes.USD] = {
		row = 'usdprize'
	},
	[prizeTypes.LOCAL_CURRENCY] = {
		header = 'localcurrency',
		headerParse = function (input)
			return {currency = string.upper(input)}
		end,
		row = 'localprize'
	},
	[prizeTypes.POINTS] = {
		header = 'points',
		headerParse = function (input)
			local pointsData = mw.loadData('Module:Points/data')
			return pointsData[input] or {title = 'Points'}
		end,
		row = 'points'
	},
	[prizeTypes.QUALIFIES] = {
		header = 'qualifies',
		headerParse = function (input)
			-- TODO: Add manual and automatic retrevial of additional data
			return {link = input:gsub(' ', '_')}
		end,
		row = 'qualified'
	},
	[prizeTypes.FREETEXT] = {
		header = 'freetext',
		headerParse = function (input)
			return {title = input}
		end,
		row = 'freetext'
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

	self.type = self.args.type.type

	self.options = self:_readStandardOptions(args)
	self.prizes = self:_readStandardPrizes(args)
	if self.options.showUSD then
		self:addPrize('USD', 1)
	end
	self.placements = self:_readPlacements(args)
end

function PrizePool:create()
	-- TODO
	mw.logObject(self)
	return ''
end

function PrizePool:_readStandardOptions(args)
	self.options = {}

	self:setOption('autoUSD', Logic.nilOr(Logic.readBoolOrNil(args.autousd), true))
	self:setOption('showUSD', Logic.nilOr(Logic.readBoolOrNil(args.showusd), true)) -- TODO: Improve
	self:setOption('prizeSummary', Logic.nilOr(Logic.readBoolOrNil(args.prizesummary), true))
	self:setOption('exchangeInfo', Logic.nilOr(Logic.readBoolOrNil(args.exchangeinfo), true))
	self:setOption('storeSmw', Logic.nilOr(Logic.readBoolOrNil(args.storesmw), true))
	self:setOption('storeLpdb', Logic.nilOr(Logic.readBoolOrNil(args.storelpdb), true))

	return self.options
end

function PrizePool:_readStandardPrizes(args)
	self.prizes = {}

	for prizeEnum in pairs(prizeTypes) do
		local prizeDatum = prizeData[prizeTypes[prizeEnum]]
		local fieldName = prizeDatum.header
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, prizeValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				local data = prizeDatum.headerParse(prizeValue)
				self:addPrize(prizeEnum, index, data)
			end
		end
	end

	return self.prizes
end

function PrizePool:_readPlacements(args)
	self.placements = {}

	local currentPlace = 0
	for placementIndex = 1, math.huge do
		local placementInput = Json.parseIfString(args[placementIndex])
		if not placementInput then
			break
		end

		local placement = {}
		-- TODO: Parse prizes
		placement.prizes = {}

		placement.opponents = {}
		for opponentIndex = 1, math.huge do
			if not placementInput[opponentIndex] then
				break
			end
			local parsedOpponent = Json.parseIfString(placementInput[opponentIndex])
			table.insert(placement.opponents, parsedOpponent)
			-- TODO: parse it into our struct
		end

		if not placementInput.place then
			placement.placeStart = currentPlace + 1
			placement.placeEnd = currentPlace + #placement.opponents
		else
			local places = Table.mapValues(mw.text.split(placementInput.place, '-'), mw.text.trim)
			placement.placeStart = places[1]
			placement.placeEnd = places[2] or places[1]
		end

		assert(placement.placeStart and placement.placeEnd, 'readPlacements: Invalid |place= provided.')
		assert(#placement.opponents > placement.placeEnd - placement.placeStart, 'readPlacements: Number of opponents')
		currentPlace = placement.placeEnd
		table.insert(self.placements, placement)
	end

	return self.placements
end

function PrizePool:setOption(option, value)
	self.options[option] = value
	return self
end

-- TODO extract parts of this to the future Enum class
local CUSTOM_TYPES_OFFSET = 100
local CUSTOM_TYPES_USED = 0
function PrizePool:addPrizeType(enum, data)
	prizeTypes[enum] = CUSTOM_TYPES_OFFSET + CUSTOM_TYPES_USED
	CUSTOM_TYPES_USED = CUSTOM_TYPES_USED + 1
	prizeData[prizeTypes[enum]] = data
	return self
end

function PrizePool:addPrize(enum, index, data)
	assert(prizeTypes[enum], 'addPrize: Not a valid prizeEnum!')
	assert(Logic.isNumeric(index), 'addPrize: Index is not numeric!')
	data = data or {}
	table.insert(self.prizes, {id = enum .. index, enum = enum, index = index, data = data})
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
