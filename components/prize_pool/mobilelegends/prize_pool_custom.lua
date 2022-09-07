---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {32, 16, 8, 4, 2}

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart
	)

	lpdbData.publishertier = Variables.varDefault('tournament_publishertier', '')
	lpdbData.extradata.publisherpremier = Variables.varDefault('tournament_publisher_major') and 'true' or ''

	local team = lpdbData.participant or ''
	local smwPrefix = Variables.varDefault('smw_prefix', '')

	Variables.varDefine('enddate_' .. smwPrefix .. team, lpdbData.date)
	Variables.varDefine('ranking' .. smwPrefix .. '_' .. (team:lower()) .. '_pointprize', lpdbData.extradata.prizepoints)


	return lpdbData
end

function CustomPrizePool.calculateWeight(prizeMoney, tier, place)
	if String.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1

	return tierValue * math.max(prizeMoney, 1) / place
end

return CustomPrizePool
