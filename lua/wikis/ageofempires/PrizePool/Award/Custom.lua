---
-- @Liquipedia
-- page=Module:PrizePool/Award/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local AwardPrizePool = Lua.import('Module:PrizePool/Award')
local LpdbInjector = Lua.import('Module:Lpdb/Injector')

local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomAwardPrizePool = {}

local IS_AWARD = true
local PRIZE_TYPE_POINTS = 'POINTS'

-- Template entry point
---@param frame Frame
---@return Html
function CustomAwardPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.localcurrency = args.localcurrency or Variables.varDefault('tournament_currency')

	local awardsPrizePool = AwardPrizePool(args)

	awardsPrizePool:setConfigDefault('prizeSummary', false)
	awardsPrizePool:setConfigDefault('syncPlayers', true)

	awardsPrizePool:create()

	awardsPrizePool:setLpdbInjector(CustomLpdbInjector())

	return awardsPrizePool:build(IS_AWARD)
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.extradata.patch = Variables.varDefault('tournament_patch')

	-- legacy points, to be standardized
	lpdbData.extradata.points = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1)
	lpdbData.extradata.points2 = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 2)

	return lpdbData
end

return CustomAwardPrizePool
