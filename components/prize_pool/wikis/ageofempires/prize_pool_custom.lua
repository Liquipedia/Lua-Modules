---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local PRIZE_TYPE_QUALIFIES = 'QUALIFIES'
local PRIZE_TYPE_POINTS = 'POINTS'
local QUALIFIER = 'Qualifier'
local TIER_VALUE = {10, 6, 4, 2}

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.syncPlayers = true
	args.import = false

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
	if opponent.opponentData.type == Opponent.solo then
		-- legacy extradata, to be removed once unused
		lpdbData.extradata.participantname = opponent.opponentData.players[1].displayName
		lpdbData.extradata.participantteam = opponent.opponentData.players[1].team

		if opponent.additionalData.LASTVS then
			lpdbData.extradata.lastvsflag = opponent.additionalData.LASTVS.players[1].flag
			lpdbData.extradata.lastvsname = opponent.additionalData.LASTVS.players[1].displayName
		end
	end

	lpdbData.extradata.patch = Variables.varDefault('tournament_patch')

	-- legacy points, to be standardized
	lpdbData.extradata.points = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1)
	Variables.varDefine(lpdbData.objectName .. '_pointprize', lpdbData.extradata.points)
	lpdbData.extradata.points2 = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 2)
	Variables.varDefine(lpdbData.objectName .. '_pointprize2', lpdbData.extradata.points2)

	local prizeIsQualifier = function(prize)
		return prize.type == PRIZE_TYPE_QUALIFIES
	end
	local opponentHasPrize = function (prize)
		return placement:getPrizeRewardForOpponent(opponent, prize.id)
	end

	lpdbData.qualified = Array.any(Array.filter(placement.parent.prizes, prizeIsQualifier), opponentHasPrize) and 1 or 0
	if Variables.varDefault('tournament_liquipediatiertype') == QUALIFIER and lpdbData.qualified == 1 then
		lpdbData.extradata.notabilitymod = '0'
	end

	-- Variable to communicate with TeamCards
	Variables.varDefine('enddate_' .. lpdbData.participant, lpdbData.date)

	return lpdbData
end

function CustomPrizePool.calculateWeight(prizeMoney, tier, place, type)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1
	local onlineFactor = type == 'Online' and 0.65 or 1

	return tierValue * math.max(prizeMoney, 0.001) / place * onlineFactor
end

return CustomPrizePool
