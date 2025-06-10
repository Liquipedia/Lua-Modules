---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local TIER_TO_FACTOR = {
	10,
	6,
	4,
	2,
}
local TIERTYPE_TO_FACTOR = {
	['Qualifier'] = 0.5,
	['Show Match'] = 0.25,
	['Misc'] = 0.2,
}

local CustomPrizePool = {}

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.localcurrency = args.localcurrency or Variables.varDefault('tournament_currency')
	local prizePool = PrizePool(args):create()
	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_type'),
		Variables.varDefault('tournament_liquipediatiertype')
	)

	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer|string
---@param tournamentType string?
---@param tiertype string?
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, tournamentType, tiertype)
	if Logic.isEmpty(place) or place == 'l' or place == 'dq' then
		return 0
	end

	local placementFactor = tonumber(place)
	local prizeMoneyToCalculate = prizeMoney or 0
	if place == 'w' or place == 'd' or place == 'q' then
		prizeMoneyToCalculate = prizeMoneyToCalculate == 0 and 0.1 or 2
		placementFactor = 1
	end
	if prizeMoneyToCalculate == 0 then
		prizeMoneyToCalculate = 0.1
	end

	local tierFactor = TIER_TO_FACTOR[tonumber(tier)] or 1
	local tiertypeFactor = TIERTYPE_TO_FACTOR[tiertype] or 1
	local tournamentTypeFactor = tournamentType == 'Online' and 0.65 or 1

	return tierFactor * (prizeMoneyToCalculate / placementFactor) * tiertypeFactor * tournamentTypeFactor
end

return CustomPrizePool
