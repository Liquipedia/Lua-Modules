---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lpdb = require('Module:Lpdb')
local Logic = require('Module:Logic')
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
---@return Widget
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.syncPlayers = true
	args.import = true

	local prizePool = PrizePool(args) ---@type PrizePool

	local output = prizePool:create():setLpdbInjector(CustomLpdbInjector()):build()

	local function placementData(placement)
		local p = prizePool.placements[placement]
		if not p or not p.opponents or not p.opponents[1] or not p.opponents[1].opponentData then
			return
		end
		if not p.opponents[1].opponentData.players or not p.opponents[1].opponentData.players[1] then
			return
		end
		local player = p.opponents[1].opponentData.players[1] --[[@as FightersStandardPlayer]]
		return player.displayName, player.pageName, player.flag, table.concat(player.chars or {}, ',')
	end
	if prizePool.opponentType == Opponent.solo then
		local tournament = Json.parseIfTable(Variables.varDefault('tournament_extradata')) or {}
		tournament.winner, tournament.winnerlink, tournament.winnerflag, tournament.winnerheads = placementData(1)
		tournament.runnerup, tournament.runneruplink, tournament.runnerupflag, tournament.runnerupheads = placementData(2)
		mw.ext.LiquipediaDB.lpdb_tournament('tournament_' .. Variables.varDefault('tournament_name', ''), {
			extradata = Json.stringify(tournament)
		})
	end

	return output
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

	if not Variables.varExists('circuit') then
		return lpdbData
	end

	lpdbData.extradata.circuit = Variables.varDefault('circuit')
	lpdbData.extradata.circuit_tier = Variables.varDefault('circuit_tier')
	lpdbData.extradata.circuit2 = Variables.varDefault('circuit2')
	lpdbData.extradata.circuit2_tier = Variables.varDefault('circuit2_tier')

	Array.forEach(Array.filter(placement.parent.prizes, function (prize)
		return prize.type == PRIZE_TYPE_POINTS
	end), function (prize)
		if Opponent.isTbd(opponent.opponentData) then
			return
		end
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
	local opponentData = Opponent.fromLpdbStruct(data)
	if opponentData.type ~= Opponent.solo then return
	elseif Logic.isEmpty(prize) then return end
	local player = opponentData.players[1]
	local pointsDataPoint = Lpdb.DataPoint:new{
		objectname = 'Points_' .. player.pageName,
		type = 'points',
		name = mw.ext.TeamLiquidIntegration.resolve_redirect(data.extradata.circuit),
		information = player.pageName,
		date = data.date,
		extradata = {
			points = prize,
			placement = data.placement,
			tournament = Variables.varDefault('tournament_link'),
			parent = Variables.varDefault('tournament_parent'),
			shortname = Variables.varDefault('tournament_name'),
			participant = player.pageName,
			game = Variables.varDefault('tournament_game'),
			type = Variables.varDefault('tournament_type'),
			participantname = player.displayName,
			participantflag = player.flag,
			publishertier = data.extradata.circuit_tier or Variables.varDefault('circuittier'),
			region = Variables.varDefault('circuitregion'),
		}
	}
	pointsDataPoint:save()
end

return CustomPrizePool
