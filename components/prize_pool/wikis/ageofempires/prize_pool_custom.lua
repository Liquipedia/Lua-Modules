---
-- @Liquipedia
-- wiki=ageofempires
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

local TIER_VALUE = {10, 6, 4, 2}

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.opponentLibrary = 'Opponent/Custom'
	args.loadFlags = true
	args.loadTeams = true

	local prizePool = PrizePool(args)
		:create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_type')
	)
	if opponent.opponentData.type == 'solo' then
		lpdbData.participantflag = opponent.opponentData.players[1].flag
		lpdbData.extradata.participantname = opponent.opponentData.players[1].displayName

		if opponent.additionalData.LASTVS ~= nil then
			lpdbData.extradata.lastvsflag = opponent.additionalData.LASTVS.players[1].flag
			lpdbData.extradata.lastvsname = opponent.additionalData.LASTVS.players[1].displayName
		end
	end

	return lpdbData
end

function CustomPrizePool.calculateWeight(prizeMoney, tier, place, type)
	if String.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1
	local onlineFactor = type == 'Online' and 0.65 or 1

	return tierValue * math.max(prizeMoney, 0.001) / place * onlineFactor
end

return CustomPrizePool
