---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Json = require('Module:Json')
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

	lpdbData.extradata.circuit = Variables.varDefault('circuit')
	lpdbData.extradata.circuit_tier = Variables.varDefault('circuit_tier')
	lpdbData.extradata.circuit2 = Variables.varDefault('circuit2')
	lpdbData.extradata.circuit2_tier = Variables.varDefault('circuit2_tier')

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
