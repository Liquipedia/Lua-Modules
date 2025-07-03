---
-- @Liquipedia
-- page=Module:PrizePool/Award/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local AwardPrizePool = Lua.import('Module:PrizePool/Award')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local PRIZE_TYPE_POINTS = 'POINTS'
local IS_AWARD = true

local _series
local _tier
local _tournament_name

-- Template entry point
---@param frame Frame
---@return Html
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	-- set some default values
	args.prizesummary = Logic.emptyOr(args.prizesummary, false)
	args.exchangeinfo = Logic.emptyOr(args.exchangeinfo, false)
	args.storelpdb = Logic.emptyOr(args.storelpdb, Namespace.isMain())
	args.syncPlayers = Logic.emptyOr(args.syncPlayers, true)

	-- overwrite some wiki vars for this PrizePool call
	_tournament_name = args['tournament name']
	_series = args.series
	_tier = args.tier or Variables.varDefault('tournament_liquipediatier')

	-- fixed setting
	args.resolveRedirect = true

	local prizePool = AwardPrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	local builtPrizePool = prizePool:build(IS_AWARD)

	return builtPrizePool
end

---@param lpdbData placement
---@param placement PrizePoolPlacement
---@param opponent BasePlacementOpponent
---@return placement
function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	-- make these available for the stash further down
	lpdbData.liquipediatier = _tier or lpdbData.liquipediatier
	lpdbData.liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype') or lpdbData.liquipediatiertype
	lpdbData.type = Variables.varDefault('tournament_type') or lpdbData.type

	Table.mergeInto(lpdbData.extradata, {
		seriesnumber = CustomPrizePool._seriesNumber(),

		-- to be removed once poinst storage is standardized
		points = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1),
		points2 = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 2),
	})

	lpdbData.tournament = _tournament_name
	lpdbData.series = _series

	local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0
	lpdbData.objectName = CustomPrizePool._overwriteObjectName(lpdbData, prizePoolIndex)

	return lpdbData
end

---@param lpdbData placement
---@param prizePoolIndex integer
---@return string
function CustomPrizePool._overwriteObjectName(lpdbData, prizePoolIndex)
	if lpdbData.opponenttype == Opponent.team then
		return lpdbData.objectName .. '_' .. prizePoolIndex
	end

	return lpdbData.objectName
end

---@return string
function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
end

return CustomPrizePool
