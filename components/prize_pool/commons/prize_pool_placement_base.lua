---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Placement/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local BASE_CURRENCY = 'USD'
local LOCAL_CURRENCY_VARIABLE_POST_FIX = 'local'
local PRIZE_TYPE_BASE_CURRENCY = 'BASE_CURRENCY'
local PRIZE_TYPE_LOCAL_CURRENCY = 'LOCAL_CURRENCY'
local PRIZE_TYPE_PERCENTAGE = 'PERCENT'

--- @class BasePlacement
--- A BasePlacement is a set of opponents who all share the same final place/award in the tournament.
--- Its input is generally a table created by `Template:Slot`.
--- It has a range from placeStart to placeEnd (e.g. 5 to 8) or a slotSize (count) or an award.
--- @field parent BasePrizePool
--- @field count integer
--- @field opponents BasePlacementOpponent
local BasePlacement = Class.new(function(self, ...) self:init(...) end)

---@class BasePlacementOpponent
---@field opponentData standardOpponent
---@field prizeRewards table
---@field additionalData table?
---@field date osdate|string?

--- @param args table Input information
--- @param parent BasePrizePool The PrizePool this BasePlacement is part of
--- @return self
function BasePlacement:init(args, parent)
	self.args = Table.deepCopy(args)
	self.parent = parent
	self.prizeTypes = parent.prizeTypes
	self.date = self.args.date or parent.date
	self.hasBaseCurrency = false

	self.prizeRewards = self:_readPrizeRewards(self.args)

	return self
end

--- Parse the input for available rewards of prizes, for instance how much money a team would win.
--- This also checks if the BasePlacement instance has a dollar reward and assigns a variable if so.
---@param args table
---@return table
function BasePlacement:_readPrizeRewards(args)
	local rewards = {}

	-- Loop through all prizes that have been defined in the header
	Array.forEach(self.parent.prizes, function (prize)
		local prizeData = self.prizeTypes[prize.type]
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

	-- Special case for Base Currency, as it's not defined in the header.
	local baseType = self.prizeTypes[PRIZE_TYPE_BASE_CURRENCY]
	if baseType.row and args[baseType.row] then
		self.hasBaseCurrency = true
		rewards[PRIZE_TYPE_BASE_CURRENCY .. 1] = baseType.rowParse(self, args[baseType.row], args, 1)
	end

	return rewards
end

---@param args table
---@return table[]
function BasePlacement:parseOpponents(args)
	return Array.mapIndexes(function(opponentIndex)
		local opponentInput = Json.parseIfString(args[opponentIndex])
		local opponent = {opponentData = {}, prizeRewards = {}, additionalData = {}}
		if not opponentInput then
			if self:_shouldAddTbdOpponent(opponentIndex) then
				opponent.opponentData = Opponent.tbd(self.parent.opponentType)
			else
				return
			end
		else
			-- Set the date
			if not BasePlacement._isValidDateFormat(opponentInput.date) then
				opponentInput.date = self.date
			end

			-- Parse Opponent Data
			if opponentInput.type then
				self.parent:assertOpponentStructType(opponentInput)
			else
				opponentInput.type = self.parent.opponentType
			end
			opponent.opponentData = self:parseOpponentArgs(opponentInput, opponentInput.date)

			opponent.prizeRewards = self:_readPrizeRewards(opponentInput)
			opponent.additionalData = self:readAdditionalData(opponentInput)

			-- Set date
			opponent.date = opponentInput.date
		end
		return opponent
	end)
end

---@param opponentIndex integer
---@param place any
---@return boolean
function BasePlacement:_shouldAddTbdOpponent(opponentIndex, place)
	-- We want at least 1 opponent present for all placements
	if opponentIndex == 1 then
		return true
	end
	-- If the fillPlaceRange option is disabled or we do not have a give placeRange do not fill up further
	if not self.parent.options.fillPlaceRange or not self.count then
		return false
	end
	-- Only fill up further with TBD's if there is free space in the placeRange/slot
	if opponentIndex <= self.count then
		return true
	end
	return false
end

---@param args table
function BasePlacement:readAdditionalData(args)
	error('Function readAdditionalData needs to be implemented by child class of `PrizePool/Placement/Base`')
end

---@param input table|string?
---@param date string|number?
---@return standardOpponent
function BasePlacement:parseOpponentArgs(input, date)
	-- Allow for lua-table, json-table and just raw string input
	local opponentArgs = Json.parseIfTable(input) or (type(input) == 'table' and input or {input})
	opponentArgs.type = opponentArgs.type or self.parent.opponentType
	assert(Opponent.isType(opponentArgs.type), 'Invalid type')

	local opponentData
	if type(opponentArgs[1]) == 'table' and opponentArgs[1].isAlreadyParsed then
		opponentData = opponentArgs[1] ---@type standardOpponent
	elseif type(opponentArgs[1]) ~= 'table' then
		opponentData = Opponent.readOpponentArgs(opponentArgs)
	end

	if not opponentData or (Opponent.isTbd(opponentData) and opponentData.type ~= Opponent.literal) then
		opponentData = Table.deepMergeInto(Opponent.tbd(opponentArgs.type), opponentData or {})
	end

	return Opponent.resolve(opponentData, date, {syncPlayer = self.parent.options.syncPlayers, overwritePageVars = true})
end

---@param opponent BasePlacementOpponent
---@param prize string
---@return string|number|boolean?
function BasePlacement:getPrizeRewardForOpponent(opponent, prize)
	return opponent.prizeRewards[prize] or self.prizeRewards[prize]
end

---@param prizesToUse BasePrizePoolPrize[]
---@param prizeTypes table
function BasePlacement:_setBaseFromRewards(prizesToUse, prizeTypes)
	Array.forEach(self.opponents, function(opponent)
		if opponent.prizeRewards[PRIZE_TYPE_BASE_CURRENCY .. 1] or self.prizeRewards[PRIZE_TYPE_BASE_CURRENCY .. 1] then
			return
		end

		local baseReward = 0
		Array.forEach(prizesToUse, function(prize)
			local localMoney = opponent.prizeRewards[prize.id] or self.prizeRewards[prize.id]

			if not localMoney or localMoney <= 0 then
				return
			end

			baseReward = baseReward + prizeTypes[prize.type].convertToBaseCurrency(
				prize.data,
				localMoney,
				opponent.date,
				self.parent.options.currencyRatePerOpponent
			)
			self.parent.usedAutoConvertedCurrency = true
		end)

		opponent.prizeRewards[PRIZE_TYPE_BASE_CURRENCY .. 1] = baseReward
	end)
end

---@param prizeTypes table
---@param hasLocalCurrency boolean
function BasePlacement:_calculateFromPercentage(prizeTypes, hasLocalCurrency)
	local baseMoney = tonumber(Variables.varDefault(hasLocalCurrency and
			('tournament_prizepool' .. LOCAL_CURRENCY_VARIABLE_POST_FIX) or
			('tournament_prizepool' .. BASE_CURRENCY:lower())
		)) or 0

	Array.forEach(self.opponents, function(opponent)
		if opponent.prizeRewards[PRIZE_TYPE_BASE_CURRENCY .. 1] or self.prizeRewards[PRIZE_TYPE_BASE_CURRENCY .. 1]
			or opponent.prizeRewards[PRIZE_TYPE_LOCAL_CURRENCY .. 1] or self.prizeRewards[PRIZE_TYPE_LOCAL_CURRENCY .. 1]
			or (opponent.prizeRewards[PRIZE_TYPE_PERCENTAGE .. 1] or self.prizeRewards[PRIZE_TYPE_PERCENTAGE .. 1] or 0) == 0
		then
			return
		end

		local percentage = opponent.prizeRewards[PRIZE_TYPE_PERCENTAGE .. 1] or self.prizeRewards[PRIZE_TYPE_PERCENTAGE .. 1]
		opponent.prizeRewards[(hasLocalCurrency and PRIZE_TYPE_LOCAL_CURRENCY or PRIZE_TYPE_BASE_CURRENCY) .. 1]
			= baseMoney * percentage / 100
	end)
end

--- Returns true if the input matches the format of a date
---@param date string|osdate
---@return boolean
function BasePlacement._isValidDateFormat(date)
	if type(date) ~= 'string' or String.isEmpty(date) then
		return false
	end
	return date:match('%d%d%d%d%-%d%d%-%d%d') and true or false
end

return BasePlacement
