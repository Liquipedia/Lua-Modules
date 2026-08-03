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
local Opponent = Lua.import('Module:Opponent/Custom')
local PrizePool = Lua.import('Module:PrizePool')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

---@class Starcraft2PrizePoolLpdbInjector: LpdbInjector
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
	args.importLimit = tonumber(args.importLimit) or CustomPrizePool._defaultImportLimit()
	args.allGroupsUseWdl = Logic.emptyOr(args.allGroupsUseWdl, true)
	args.import = Logic.emptyOr(args.import, true)

	-- fixed setting
	args.resolveRedirect = true
	args.groupScoreDelimiter = '-'

	return PrizePool(args)
		:setConfigDefault('storeLpdb', Namespace.isMain())
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

	lpdbData.extradata = Table.mergeInto(lpdbData.extradata, {
		seriesnumber = CustomPrizePool._seriesNumber(),
		mod = Variables.varDefault('tournament_mod'),
	})

	lpdbData.objectName = CustomPrizePool._overwriteObjectName(lpdbData)

	return lpdbData
end

---@param lpdbData placement
---@return string
function CustomPrizePool._overwriteObjectName(lpdbData)
	if lpdbData.opponenttype == Opponent.team then
		local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0
		return lpdbData.objectName .. '_' .. prizePoolIndex
	end

	return lpdbData.objectName
end

---@return integer?
function CustomPrizePool._defaultImportLimit()
	local tier = tonumber(Variables.varDefault('tournament_liquipediatier'))
	if not tier then return end

	return tier >= 4 and 8
		or tier == 3 and 16
		or nil
end

---@return string
function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
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

	local placementFactor = placement.placeStart or 0
	if place == 'w' or place == 'd' or place == 'q' then
		prize = 1
		placementFactor = 1
	end

	return tierFactor * (prize / placementFactor) * tierTypeFactor
end

return CustomPrizePool
