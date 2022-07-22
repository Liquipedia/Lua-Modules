---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Weight = require('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {8, 4, 2}
local TYPE_MODIFIER = {Online = 0.65}

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = Weight.calc(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_type'),
		Variables.varDefault('tournament_liquipediatiertype')

	)

	return lpdbData
end

return CustomPrizePool
