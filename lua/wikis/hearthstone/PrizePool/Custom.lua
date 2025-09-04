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

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {8, 4, 2}
local TIER_TYPE_MODIFIER = {Showmatch = 0.01, Monthly = 0.4, Weekly = 0.2, Daily = 0.1}

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
		placement.placeStart,
		Variables.varDefault('tournament_liquipediatiertype')
	)

	local team = lpdbData.participant or ''
	local lpdbPrefix = Variables.varDefault('lpdb_prefix') or ''

	Variables.varDefine('enddate_' .. lpdbPrefix .. team, lpdbData.date)
	Variables.varDefine('ranking' .. lpdbPrefix .. '_' .. (team:lower()) .. '_pointprize', lpdbData.extradata.prizepoints)
	Variables.varDefine('ranking' .. lpdbPrefix .. '_' .. (team:lower()) .. '_pointprize2',
		lpdbData.extradata.prizepoints2)

	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer
---@param tierType string?
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, tierType)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tonumber(tier)] or 1

	return tierValue * math.max(prizeMoney, 1) * (TIER_TYPE_MODIFIER[tierType] or 1) / place
end

return CustomPrizePool
