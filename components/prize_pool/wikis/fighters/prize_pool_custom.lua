---
-- @Liquipedia
-- wiki=fighters
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
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

local PRIZE_TYPE_POINTS = 'POINTS'
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
		lpdbData.players = {
			p1 = opponent.opponentData.players[1].pageName,
			p2 = opponent.opponentData.players[2].pageName,
		}
	end

	lpdbData.extradata.matchid = opponent.additionalData.LASTVSMATCHID

	lpdbData.extradata.circuit = Variables.varDefault('circuit')
	lpdbData.extradata.circuit_tier = Variables.varDefault('circuit_tier')
	lpdbData.extradata.circuit2 = Variables.varDefault('circuit2')
	lpdbData.extradata.circuit2_tier = Variables.varDefault('circuit2_tier')

	Array.forEach(Array.filter(placement.parent.prizes, function (prize)
		return prize.type == PRIZE_TYPE_POINTS
	end), function (prize)
		CustomPrizePool.addPointsDatapoint(lpdbData, placement:getPrizeRewardForOpponent(opponent, prize.id))
	end)

	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place)
	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier)] or 1

	return (tierValue * prizeMoney) / place
end

---@param data placement
---@param prize string|number|boolean?
function CustomPrizePool.addPointsDatapoint(data, prize)
	mw.ext.LiquipediaDB.lpdb_datapoint('Points_' .. data.participant, {
		type = 'points',
		name = data.extradata.circuit,
		information = data.participant,
		date = data.date,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			points = prize,
			placement = data.placement,
			tournament = data.tournament,
			parent = data.parent,
			shortname = data.shortname,
			participant = data.participant,
			game = data.game,
			type = data.type,
			publishertier = data.extradata.circuit_tier or Variables.varDefault('tournament_region')
		})
	})
end

return CustomPrizePool
