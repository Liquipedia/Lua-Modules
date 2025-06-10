---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local PRIZE_TYPE_POINTS = 'POINTS'

local TIER_VALUE = {32, 16, 8, 4, 2}
local TYPE_MODIFIER = {Online = 0.65}

-- Template entry point
---@param frame Frame
---@return Html
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
	lpdbData.weight = CustomPrizePool.calculateWeight(
		lpdbData.prizemoney,
		Variables.varDefault('tournament_liquipediatier'),
		placement.placeStart,
		Variables.varDefault('tournament_type')
	)

	local sixInvitePoints = Array.filter(placement.parent.prizes, function (prize)
		return prize.type == PRIZE_TYPE_POINTS and prize.data.title == 'SI'
	end)[1]

	if sixInvitePoints then
		local points = placement:getPrizeRewardForOpponent(opponent, sixInvitePoints.id)
		---for points it can never be boolean
		---@cast points -boolean
		CustomPrizePool.addSiDatapoint(lpdbData, points)
	end

	Variables.varDefine(lpdbData.participant:lower() .. '_prizepoints', lpdbData.extradata.prizepoints)

	return lpdbData
end

---@param prizeMoney number
---@param tier string?
---@param place integer
---@param type string?
---@return integer
function CustomPrizePool.calculateWeight(prizeMoney, tier, place, type)
	if Logic.isEmpty(tier) then
		return 0
	end

	local tierValue = TIER_VALUE[tier] or TIER_VALUE[tonumber(tier) or ''] or 1

	return tierValue * math.max(prizeMoney, 1) * (TYPE_MODIFIER[type] or 1) / place
end

---@param data placement
---@param siPoints number|string?
function CustomPrizePool.addSiDatapoint(data, siPoints)
	local pageName = mw.title.getCurrentTitle().fullText
	mw.ext.LiquipediaDB.lpdb_datapoint('si_points_' .. pageName .. '_' .. data.placement .. '_' .. data.participant, {
		type = 'si_points',
		name = data.participant,
		date = data.date,
		information = siPoints,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			placement = data.placement,
		})
	})
end

return CustomPrizePool
