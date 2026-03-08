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
local HighlightConditions = Lua.import('Module:HighlightConditions')

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {8, 4, 2}
local TIER_TYPE_MODIFIER = {Showmatch = 0,  Qualifier = 0.25, Monthly = 0.4, Weekly = 0.1}

-- Template entry point
---@param frame Frame
---@return Widget
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	args.allGroupsUseWdl = true
	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	return prizePool:build()
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.publishertier = Variables.varDefault('tournament_publishertier', '')
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_liquipediatiertype'),
		HighlightConditions.tournament(lpdbData)
	)

	local team = lpdbData.participant or ''
	local lpdbPrefix = Variables.varDefault('lpdb_prefix', '')

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
---@param isHighlighted boolean
---@return number
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, tierType, isHighlighted)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1
	local prizeFactor = (1000000 + prizeMoney) / 1000000
	local tierTypeFactor = TIER_TYPE_MODIFIER[tierType] or 1
	local highlightedFactor = isHighlighted and 2 or 1

	return prizeFactor * tierValue * tierTypeFactor * highlightedFactor / place
end

return CustomPrizePool
