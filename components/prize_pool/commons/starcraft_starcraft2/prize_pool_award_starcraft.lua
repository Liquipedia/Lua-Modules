---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Award/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local AwardPrizePool = Lua.import('Module:PrizePool/Award', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local CustomLpdbInjector = Class.new(LpdbInjector)

local pageVars = PageVariableNamespace('PrizePool')

local CustomPrizePool = {}

local PRIZE_TYPE_POINTS = 'POINTS'
local IS_AWARD = true

local _lpdb_stash = {}
local _series
local _tier
local _tournament_name
local _series_number

-- Template entry point
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

	-- stash seriesNumber
	_series_number = CustomPrizePool._seriesNumber()

	local prizePool = AwardPrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	local builtPrizePool = prizePool:build(IS_AWARD)

	if Logic.readBool(args.storelpdb) then
		local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0

		-- stash the lpdb_placement data so teamCards can use them
		pageVars:set('placementRecords.' .. prizePoolIndex, Json.stringify(_lpdb_stash))
	end

	return builtPrizePool
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	-- make these available for the stash further down
	lpdbData.liquipediatier = _tier
	lpdbData.liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype')
	lpdbData.type = Variables.varDefault('tournament_type')

	Table.mergeInto(lpdbData.extradata, {
		seriesnumber = _series_number,

		 -- to be removed once poinst storage is standardized
		points = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1),
		points2 = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 2),
	})

	lpdbData.tournament = _tournament_name
	lpdbData.series = _series

	local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0
	lpdbData.objectName = CustomPrizePool._overwriteObjectName(lpdbData, prizePoolIndex)

	table.insert(_lpdb_stash, Table.deepCopy(lpdbData))

	return lpdbData
end

function CustomPrizePool._overwriteObjectName(lpdbData, prizePoolIndex)
	if lpdbData.opponenttype == Opponent.team then
		return lpdbData.objectName .. '_' .. prizePoolIndex
	end

	return lpdbData.objectName
end

function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
end

return CustomPrizePool
