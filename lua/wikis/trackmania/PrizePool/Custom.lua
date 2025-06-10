---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local PRIZE_TYPE_POINTS = 'POINTS'
local PRIZE_TITLE_WORLD_TOUR = 'WT'

local TIER_VALUE = {8, 4, 2}
local TYPE_MODIFIER = {Online = 0.65}

-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	args.syncPlayers = true

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

	local worldTourPoints = Array.filter(placement.parent.prizes, function (prize)
		return prize.type == PRIZE_TYPE_POINTS and prize.data.title == PRIZE_TITLE_WORLD_TOUR
	end)[1]

	if worldTourPoints then
		local points = placement:getPrizeRewardForOpponent(opponent, worldTourPoints.id)
		---for points it can never be boolean
		---@cast points -boolean
		lpdbData.extradata.prizepoints = points
		lpdbData.extradata.prizepointsTitle = 'wt_points'
	end

	Variables.varDefine(lpdbData.participant:lower() .. '_prizepoints', lpdbData.extradata.prizepoints)
	Variables.varDefine(lpdbData.participant:lower() .. '_prizepointsTitle', lpdbData.extradata.prizepointsTitle)

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

	local tierValue = TIER_VALUE[tonumber(tier)] or 1

	return tierValue * (prizeMoney * 1000 + 1000 - place) / place * (TYPE_MODIFIER[type] or 1)
end

return CustomPrizePool
