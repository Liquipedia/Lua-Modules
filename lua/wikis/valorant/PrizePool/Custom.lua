---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool')
local Opponent = Lua.import('Module:Opponent')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local TIER_VALUE = {10, 6, 4, 2}
local TYPE_MODIFIER = {Online = 0.65}
local TIER_TYPE_MODIFIER = {Showmatch = 0,  Misc = 0.25, Qualifier = 0.25, Monthly = 0.4, Weekly = 0.1}

-- Template entry point
---@param frame Frame
---@return Widget
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
	lpdbData.publishertier = Variables.varDefault('tournament_publishertier', '')
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_type'),
		Variables.varDefault('tournament_liquipediatiertype'),
		HighlightConditions.tournament(lpdbData)
	)

	local participantLower = mw.ustring.lower(lpdbData.participant)

	Variables.varDefine(participantLower .. '_prizepoints', lpdbData.extradata.prizepoints)
	Variables.varDefine(participantLower .. '_prizepoints2', lpdbData.extradata.prizepoints2)
	Variables.varDefine('enddate_'.. lpdbData.participant .. '_date', lpdbData.date)
	Variables.varDefine('status'.. lpdbData.participant .. '_date', lpdbData.date)

	if Opponent.isTbd(opponent.opponentData) then
		Variables.varDefine('minimum_secured', lpdbData.extradata.prizepoints)
	end

	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer
---@param tournamentType string?
---@param tierType string?
---@param isHighlighted boolean
---@return number
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, tournamentType, tierType, isHighlighted)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1
	local prizeFactor = (1000000 + prizeMoney) / 1000000
	local tierTypeFactor = TIER_TYPE_MODIFIER[tierType] or 1
	local highlightedFactor = isHighlighted and 2 or 1
	local typeFactor = TYPE_MODIFIER[type] or 1

	return prizeFactor * tierValue * tierTypeFactor * highlightedFactor * typeFactor / place
end

return CustomPrizePool
