---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Award/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local AwardPrizePool = Lua.import('Module:PrizePool/Award', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomAwardPrizePool = {}

local IS_AWARD = true

-- Template entry point
function CustomAwardPrizePool.run(frame)
	local awardsPrizePool = AwardPrizePool(Arguments.getArgs(frame))

	awardsPrizePool:setConfigDefault('prizeSummary', false)
	awardsPrizePool:setConfigDefault('syncPlayers', true)

	awardsPrizePool:setLpdbInjector(CustomLpdbInjector())

	return awardsPrizePool:create():build(IS_AWARD)
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.publishertier = Variables.varDefault('tournament_publishertier', '')
	return lpdbData
end

return CustomAwardPrizePool
