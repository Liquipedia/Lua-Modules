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

local TIER_VALUE = {8, 4, 2}
local TYPE_MODIFIER = {Online = 0.65}

-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.allGroupsUseWdl = true
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

	lpdbData.extradata.series = Variables.varDefault('tournament_series', '')
	lpdbData.extradata.liquipediatiertype2 = Variables.varDefault('tournament_tiertype2', '')
	lpdbData.extradata.notabilitymod = Variables.varDefault('tournament_notability_mod', '1')

	local participantLower = mw.ustring.lower(lpdbData.participant)

	Variables.varDefine(participantLower .. '_prizepoints', lpdbData.extradata.prizepoints)
	Variables.varDefine('enddate_'.. participantLower, lpdbData.date)

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

	return tierValue + tierValue * prizeMoney * (TYPE_MODIFIER[type] or 1) / place
end

return CustomPrizePool
