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
	[prizeTypes.USD] = {row = 'usdprize'},
	[prizeTypes.LOCAL_CURRENCY] = {header = 'localcurrency', row = 'localprize'},
	[prizeTypes.POINTS] = {header = 'points', row = 'points'},
	[prizeTypes.QUALIFIES] = {header = 'qualifies', row = 'qualified'},
	[prizeTypes.FREETEXT] = {header = 'freetext', row = 'freetext'},
}

function PrizePool:init(args)
	self.args = args
	self.pagename = mw.title.getCurrentTitle().text
	self.args.type = Json.parseIfString(self.args.type)
	self.widgetInjector = nil
	self.lpdbInjector = nil

	if not self.args.type then
		return error('Please provide a type!')
	elseif type(self.args.type) ~= 'table' or not self.args.type.type then
		return error('Could not parse type!')
	elseif not Opponent.isType(self.args.type.type) then
		return error('Not a valid type!')
	end

	self.type = self.args.type.type

	self.options = self:_readOptions(args)
	self.prizes = self:_readPrizes(args)
	if self.options.showUSD then
		self:addPrize('USD', 1)
	end
	self.placements = {} -- TODO
end

function PrizePool:create()
	-- TODO
	mw.logObject(self)
	return ''
end

function PrizePool:_readOptions(args)
	return {
		autoUSD = Logic.nilOr(Logic.readBoolOrNil(args.autousd), true),
		showUSD = Logic.nilOr(Logic.readBoolOrNil(args.showusd), true), -- TODO: Improve
		prizeSummary = Logic.nilOr(Logic.readBoolOrNil(args.prizesummary), true),
		exchangeInfo = Logic.nilOr(Logic.readBoolOrNil(args.exchangeinfo), true),
		storeSmw = Logic.nilOr(Logic.readBoolOrNil(args.storesmw), true),
		storeLpdb = Logic.nilOr(Logic.readBoolOrNil(args.storelpdb), true),
	}
end

function PrizePool:_readPrizes(args)
	self.prizes = {}

	for prizeEnum in pairs(prizeTypes) do
		local prizeDatum = prizeData[prizeTypes[prizeEnum]]
		local fieldName = prizeDatum.header
		if fieldName then
			args[fieldName .. '1'] = args[fieldName .. '1'] or args[fieldName]
			for _, prizeValue, index in Table.iter.pairsByPrefix(args, fieldName) do
				-- TODO: parse the prizeValue into structured data
				self:addPrize(prizeEnum, index, prizeValue)
			end
		end
	end

	return self.prizes
end

function PrizePool:setOption(option, value)
	self.options[option] = value
	return self
end

-- TODO extract of this to the future Enum class
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
	table.insert(self.prizes, {enum = enum, index = index, data = data})
	return self
end

function PrizePool:setWidgetInjector(widgetInjector)
	assert(widgetInjector:is_a(WidgetInjector), "Not a WidgetIjector")
	self.widgetInjector = widgetInjector
	return self
end

function PrizePool:setLpdbInjector(lpdbInjector)
	-- TODO: Add type check
	self.lpdbInjector = lpdbInjector
	return self
end

return PrizePool
