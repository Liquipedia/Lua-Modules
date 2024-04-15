---
-- @Liquipedia
-- wiki=dota2
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
	lpdbData.extradata.series2 = Variables.varDefault('tournament_series2', '')

	return lpdbData
end

return CustomAwardPrizePool
