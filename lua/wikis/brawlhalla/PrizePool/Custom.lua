---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {8, 4, 2}

-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.syncPlayers = true
	args.import = true

	local prizePool = PrizePool(args)

	return prizePool:create():setLpdbInjector(CustomLpdbInjector()):build()
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart
	)

	if opponent.opponentData.type == Opponent.solo then
		lpdbData.mode = 'singles'
		if opponent.additionalData.LASTVS then
			lpdbData.extradata.lastvsflag = opponent.additionalData.LASTVS.players[1].flag
		end
	end

	if opponent.opponentData.type == Opponent.duo then
		lpdbData.mode = 'doubles'
	end

	lpdbData.extradata.matchid = opponent.additionalData.LASTVSMATCHID

	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place)
	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier)] or 1

	return (tierValue * Variables.varDefault('tournament_entrants', 0) + prizeMoney * 0.5) / (place * place)
end

return CustomPrizePool
