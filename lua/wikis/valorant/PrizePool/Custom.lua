---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool')
local Opponent = Lua.import('Module:Opponent')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {10, 6, 4, 2}
local TYPE_MODIFIER = {Online = 0.65}

-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_type')
	)

	local participantLower = mw.ustring.lower(lpdbData.participant)

	Variables.varDefine(participantLower .. '_prizepoints', lpdbData.extradata.prizepoints)
	Variables.varDefine('enddate_'.. lpdbData.participant .. '_date', lpdbData.date)
	Variables.varDefine('status'.. lpdbData.participant .. '_date', lpdbData.date)

	lpdbData.qualified = placement:getPrizeRewardForOpponent(opponent, 'QUALIFIES1') and 1 or 0

	if Opponent.isTbd(opponent.opponentData) then
		Variables.varDefine('minimum_secured', lpdbData.extradata.prizepoints)
	end

	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer
---@param type string?
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, type)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1

	return tierValue * math.max(prizeMoney, 1) * (TYPE_MODIFIER[type] or 1) / place
end

return CustomPrizePool
