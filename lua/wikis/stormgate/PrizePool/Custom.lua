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
local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local Namespace = Lua.import('Module:Namespace')
local PrizePool = Lua.import('Module:PrizePool')

---@class StormgatePrizePoolLpdbInjector: LpdbInjector
local CustomLpdbInjector = Class.new(LpdbInjector)

local TIER_TO_FACTOR = {
	8,
	4,
	2,
}
local DEFAULT_PRIZE_VALUE = 0.0001

local CustomPrizePool = {}

-- Template entry point
---@param frame Frame
---@return Widget
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	-- set some default values
	args.prizesummary = Logic.emptyOr(args.prizesummary, false)
	args.exchangeinfo = Logic.emptyOr(args.exchangeinfo, false)
	args.syncPlayers = Logic.emptyOr(args.syncPlayers, true)
	args.placementsExtendImportLimit = Logic.emptyOr(args.placementsExtendImportLimit, true)

	-- adjust import settings params
	args.allGroupsUseWdl = Logic.emptyOr(args.allGroupsUseWdl, true)

	-- fixed setting
	args.resolveRedirect = true
	args.groupScoreDelimiter = '-'

	return PrizePool(args):setConfigDefault('storeLpdb', Namespace.isMain())
		:create()
		:setLpdbInjector(CustomLpdbInjector())
		:build()
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.weight = CustomPrizePool._weight(lpdbData, placement)

	return lpdbData
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@return number
function CustomPrizePool._weight(lpdbData, placement)
	local place = string.lower(lpdbData.placement or '')
	if Logic.isEmpty(place) or place == 'l' or place == 'dq' then
		return 0
	end

	local tierFactor = TIER_TO_FACTOR[tonumber(lpdbData.liquipediatier)] or 1

	local tierTypeFactor = lpdbData.liquipediatiertype == 'Qualifier' and 0.001 or 1

	local prize = tonumber(lpdbData.individualprizemoney) or 0
	prize = prize ~= 0 and prize or DEFAULT_PRIZE_VALUE

	local placementFactor = tonumber(placement.placeStart) or 0
	if place == 'w' or place == 'd' or place == 'q' then
		prize = 1
		placementFactor = 1
	end

	return tierFactor * (prize / placementFactor) * tierTypeFactor
end

return CustomPrizePool
