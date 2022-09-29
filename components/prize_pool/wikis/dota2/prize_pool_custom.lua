---
-- @Liquipedia
-- wiki=dota2
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

local TIER_VALUE = {8, 4, 2}

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

	lpdbData.publishertier = Variables.varDefault('tournament_pro_circuit_tier', '')
	lpdbData.extradata.publisherpremier = Variables.varDefault('tournament_valve_premier', '')
	lpdbData.extradata.lis = Variables.varDefault('tournament_lis', '')
	lpdbData.extradata.series2 = Variables.varDefault('tournament_series2', '')

	local redirectedTeam = mw.ext.TeamLiquidIntegration.resolve_redirect(lpdbData.participant)
	local smwPrefix = Variables.varDefault('smw_prefix')
	smwPrefix = smwPrefix and (smwPrefix .. '_') or ''

	Variables.varDefine(redirectedTeam .. '_' .. smwPrefix .. 'date', lpdbData.date)
	Variables.varDefine(smwPrefix .. (redirectedTeam:lower()) .. '_prizepoints', lpdbData.extradata.prizepoints)


	return lpdbData
end

function CustomPrizePool.calculateWeight(prizeMoney, tier, place)
	if String.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1

	return tierValue * math.max(prizeMoney, 0.001) / place
end

return CustomPrizePool
