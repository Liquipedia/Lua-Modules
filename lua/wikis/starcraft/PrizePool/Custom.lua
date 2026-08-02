---
-- @Liquipedia
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local LpdbInjector = Lua.import('Module:Lpdb/Injector')
local Namespace = Lua.import('Module:Namespace')
local Opponent = Lua.import('Module:Opponent/Custom')
local PrizePool = Lua.import('Module:PrizePool')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

---@class StarcraftPrizePoolLpdbInjector: LpdbInjector
local CustomLpdbInjector = Class.new(LpdbInjector)

local TIER_TO_FACTOR = {
	8,
	4,
	2,
}
local TIER_TO_BASE_WEIGHT = {
	2000,
	200,
	20
}

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
	lpdbData.weight = CustomPrizePool._weight(lpdbData)

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

---@return string
function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
end

---@param lpdbData placement
---@return number
function CustomPrizePool._weight(lpdbData)
	local offlineFactor = lpdbData.type == 'Offline' and 1.5 or 1

	local placementFactor
	local placements = Array.parseCommaSeparatedString(lpdbData.placement, '-')
	if placements[2] then
		placementFactor = (placements[1] + placements[2]) / 2
	else
		placementFactor = tonumber(placements[1]) or 999
	end

	local tierFactor = (lpdbData.liquipediatiertype == 'Qualifier' or lpdbData.liquipediatiertype == 'Showmatch') and 0.5
		or TIER_TO_FACTOR[tonumber(lpdbData.liquipediatier)]
		or 1

	local baseWeight = (lpdbData.liquipediatiertype == 'Qualifier' or lpdbData.liquipediatiertype == 'Showmatch') and 0
		or TIER_TO_BASE_WEIGHT[tonumber(lpdbData.liquipediatier)]
		or 10

	return offlineFactor * tierFactor * (lpdbData.individualprizemoney + baseWeight / placementFactor) / placementFactor
end

return CustomPrizePool
