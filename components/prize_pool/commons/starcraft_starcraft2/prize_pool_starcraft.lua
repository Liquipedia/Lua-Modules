---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Info = require('Module:Info')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Weight = require('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool')

local LpdbInjector = Lua.import('Module:Lpdb/Injector')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local CustomLpdbInjector = Class.new(LpdbInjector)

local CustomPrizePool = {}

local PRIZE_TYPE_POINTS = 'POINTS'
local SC2 = 'starcraft2'

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
	args.syncPlayers = Logic.emptyOr(args.syncPlayers, true)
	args.placementsExtendImportLimit = Logic.emptyOr(args.placementsExtendImportLimit, true)

	-- overwrite some wiki vars for this PrizePool call
	_tournament_name = args['tournament name']
	_series = args.series
	_tier = args.tier or Variables.varDefault('tournament_liquipediatier')

	-- adjust import settings params
	args.importLimit = tonumber(args.importLimit) or CustomPrizePool._defaultImportLimit()
	args.allGroupsUseWdl = Logic.emptyOr(args.allGroupsUseWdl, true)
	args.import = Logic.emptyOr(args.import, true)

	-- fixed setting
	args.resolveRedirect = true
	args.groupScoreDelimiter = '-'

	local prizePool = PrizePool(args)

	prizePool:setConfigDefault('storeLpdb', Namespace.isMain())

	prizePool:create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	local builtPrizePool = prizePool:build()

	local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0
	-- set an additional wiki-var for legacy reasons so that combination with award prize pools still work
	Variables.varDefine('prize pool table id', prizePoolIndex)

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

	lpdbData.weight = Weight.calc(
		lpdbData.individualprizemoney,
		lpdbData.liquipediatier,
		lpdbData.placement,
		lpdbData.liquipediatiertype,
		lpdbData.type
	)

	if type(lpdbData.opponentplayers) == 'table' then
		-- following 2 lines as legacy support, to be removed once it is clear they are not needed anymore
		lpdbData.players = Table.copy(lpdbData.opponentplayers)
		---@diagnostic disable-next-line: inject-field
		lpdbData.players.type = lpdbData.opponenttype
	end

	lpdbData.extradata = Table.mergeInto(lpdbData.extradata, {
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

---@return integer?
function CustomPrizePool._defaultImportLimit()
	if Info.wikiName ~= SC2 then
		return
	end

	local tier = tonumber(_tier)
	if not tier then
		mw.log('Prize Pool Import: Unset/Invalid liquipediatier')
		return
	end

	return tier >= 4 and 8
		or tier == 3 and 16
		or nil
end

---@return string
function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
end

return CustomPrizePool
