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
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Weight = require('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local SmwInjector = Lua.import('Module:Smw/Injector', {requireDevIfEnabled = true})

local Opponent = require('Module:OpponentLibraries').Opponent

local CustomLpdbInjector = Class.new(LpdbInjector)
local CustomSmwInjector = Class.new(SmwInjector)

local pageVars = PageVariableNamespace('PrizePool')

local CustomPrizePool = {}

local PRIZE_TYPE_POINTS = 'POINTS'
local SC2 = 'starcraft2'

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
	args.storesmw = Logic.emptyOr(args.storesmw, Namespace.isMain())
	args.syncPlayers = Logic.emptyOr(args.syncPlayers, true)

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

	-- stash seriesNumber
	_series_number = CustomPrizePool._seriesNumber()

	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())
	prizePool:setSmwInjector(CustomSmwInjector())

	local builtPrizePool = prizePool:build()

	local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0
	-- set an additional wiki-var for legacy reasons so that combination with award prize pools still work
	Variables.varDefine('prize pool table id', prizePoolIndex)

	if Logic.readBool(args.storelpdb) then
		-- stash the lpdb_placement data so teamCards can use them
		pageVars:set('placementRecords.' .. prizePoolIndex, Json.stringify(_lpdb_stash))
	end

	return builtPrizePool
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	lpdbData.publishertier = Variables.varDefault('featured')

	-- make these available for the stash further down
	lpdbData.liquipediatier = _tier
	lpdbData.liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype')
	lpdbData.type = Variables.varDefault('tournament_type')

	lpdbData.weight = Weight.calc(
		lpdbData.individualprizemoney,
		lpdbData.liquipediatier,
		lpdbData.placement,
		lpdbData.liquipediatiertype,
		lpdbData.type
	)

	if type(lpdbData.opponentplayers) == 'table' then
		-- following 2 lines as legacy support, to be removed once consumers are adjusted
		lpdbData.players = Table.copy(lpdbData.opponentplayers)
		lpdbData.players.type = lpdbData.opponenttype
	end

	lpdbData.extradata = Table.mergeInto(lpdbData.extradata, {
		seriesnumber = _series_number,

		 -- to be removed once poinst storage is standardized
		points = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1),
		points2 = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 2),
	})

	-- remove the following line once the consumers have been updated
	lpdbData.mode = CustomPrizePool._getMode(lpdbData.opponenttype, opponent.opponentData)

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

function CustomPrizePool._getMode(opponentType, opponent)
	if (opponent or {}).isArchon then
		return 'archon'
	end

	return Opponent.toLegacyMode(opponentType or '', opponentType or '')
end

function CustomSmwInjector:adjust(smwEntry, lpdbEntry)
	local lastVs = Json.parseIfString(lpdbEntry.lastvsdata) or {}

	-- fix lastvs opponent stuff
	if Table.isNotEmpty(lastVs) then
		lastVs = Opponent.fromLpdbStruct(lastVs)
		if lastVs.type == Opponent.solo then
			smwEntry['has last opponent page'] = lastVs.players[1].pageName
			smwEntry['has last opponent'] = lastVs.players[1].displayName
		elseif Opponent.typeIsParty(lastVs.type) then
			smwEntry['has last opponent'] = nil
			for playerIndex, player in ipairs(lastVs.players) do
				smwEntry['has last opponent ' .. playerIndex .. ' page'] = player.pageName
				smwEntry['has last opponent ' .. playerIndex] = player.displayName
			end
		elseif lastVs.type == Opponent.team then
			smwEntry['has last opponent'] = lastVs.name
		end
	end

	return CustomPrizePool._opponentSmwProps(smwEntry, lpdbEntry)
end

function CustomPrizePool._opponentSmwProps(smwEntry, lpdbData)
	if lpdbData.opponenttype == Opponent.team or lpdbData.opponenttype == Opponent.literal then
		return smwEntry
	elseif lpdbData.opponenttype == Opponent.solo then
		local playersData = Json.parseIfString(lpdbData.players) or {}
		smwEntry['has race'] = playersData.p1race
		return smwEntry
	end

	local playersData = Json.parseIfString(lpdbData.players) or {}
	local isArchon = playersData.isArchon
	if isArchon then
		smwEntry['is Archon'] = 'true'
	end

	for prefix, playerPage, playerIndex in Table.iter.pairsByPrefix(playersData, 'p') do
		-- skip first as it is already processed and syntax is different
		if playerIndex ~= 1 then
			smwEntry['has player ' .. playerIndex] = playersData[prefix .. 'dn']
			smwEntry['has player ' .. playerIndex .. ' page'] = playerPage
			smwEntry['has player ' .. playerIndex .. ' flag'] = playersData[prefix .. 'flag']
			smwEntry['has player ' .. playerIndex .. ' team'] = playersData[prefix .. 'team']
			smwEntry['has player ' .. playerIndex .. ' race'] = (not isArchon) and playersData[prefix .. 'race'] or nil
		end
	end

	return smwEntry
end

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

function CustomPrizePool._seriesNumber()
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return seriesNumber and string.format('%05d', seriesNumber) or ''
end

return CustomPrizePool
