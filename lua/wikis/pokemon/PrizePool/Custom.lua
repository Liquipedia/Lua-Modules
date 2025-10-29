---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')

local Opponent = Lua.import('Module:Opponent/Custom')

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
	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
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

	local lastVs = ((opponent or {}).additionalData or {}).LASTVS or {}
	if lastVs.type == Opponent.solo then
		local playerData = (lastVs.players or {})[1] or {}
		lpdbData.extradata.lastvsflag = playerData.flag
		lpdbData.extradata.lastvsdisplayname = playerData.displayName
	end

	local team = lpdbData.participant or ''
	local lpdbPrefix = placement.parent.options.lpdbPrefix

	Variables.varDefine('enddate_' .. lpdbPrefix .. team, lpdbData.date)
	Variables.varDefine('ranking' .. lpdbPrefix .. '_' .. (team:lower()) .. '_pointprize', lpdbData.extradata.prizepoints)
	Variables.varDefine('ranking' .. lpdbPrefix .. '_' .. (team:lower()) .. '_pointprize2',
		lpdbData.extradata.prizepoints2)


	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1

	return tierValue * math.max(prizeMoney, 1) / place
end

return CustomPrizePool
