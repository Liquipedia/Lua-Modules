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
local Opponent = require('Module:Opponent')

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
	if opponent.opponentData.type == Opponent.solo then
		lpdbData.participantflag = opponent.opponentData.players[1].flag

		-- legacy extradata, to be removed once unused
		lpdbData.extradata.participantname = opponent.opponentData.players[1].displayName
		lpdbData.extradata.participantteam = opponent.opponentData.players[1].team

		if opponent.additionalData.LASTVS then
			lpdbData.extradata.lastvsflag = opponent.additionalData.LASTVS.players[1].flag
			lpdbData.extradata.lastvsname = opponent.additionalData.LASTVS.players[1].displayName
		end

		lpdbData.extradata.patch = Variables.varDefault('tournament_patch')
		lpdbData.extradata.monthandday = placement.date:sub(-5)
	end

	-- legacy points, to be standardized
	lpdbData.extradata.points = placement.prizeRewards.POINTS1
	lpdbData.extradata.points2 = placement.prizeRewards.POINTS2

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
