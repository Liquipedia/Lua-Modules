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
local StarcraftOpponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})

local CustomLpdbInjector = Class.new(LpdbInjector)
local CustomSmwInjector = Class.new(SmwInjector)

local pageVars = PageVariableNamespace('PrizePool')

local CustomPrizePool = {}

local PRIZE_TYPE_POINTS = 'POINTS'
local SCORE_STATUS = 'S'
local WALKOVER_VS_STATUS = 'W'
local OPPONENT_TYPE_TO_MODE = {
	solo = '1v1',
	duo = '2v2',
	trio = '3v3',
	quad = '4v4',
	team = 'team',
}
local IMPORT_START_DATE = '2022-01-14'
local PLACE_TO_KEY_PREFIX = {'winner', 'runnerup', 'third', 'fourth'}
local SEMIFINALS_PREFIX = 'sf'
local TBD = 'TBD'
local SC2 = 'starcraft2'

local _lpdb_stash = {}
local _series
local _tier
local _tournament_extradata_cache = {{}, {}, {}, {}, ['3-4'] = {}}
local _tournament_name

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)

	-- use different opponent modules
	args.opponentLibrary = 'Opponent/Starcraft'
	args.opponentDisplayLibrary = 'OpponentDisplay/Starcraft'

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
	args.importEnableStartDate = IMPORT_START_DATE

	-- fixed setting
	args.resolveRedirect = true

	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())
	prizePool:setSmwInjector(CustomSmwInjector())

	local buildPrizePool = prizePool:build()

	local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0
	-- set an additional wiki-var for legacy reasons so that combination with award prize pools still work
	Variables.varDefine('prize pool table id', prizePoolIndex)
	if prizePoolIndex == 1 and Logic.readBool(Logic.emptyOr(args.storeTournament, Namespace.isMain())) then
		CustomPrizePool._storeIntoTournamentLpdb()
	end

	if Logic.readBool(args.storelpdb) then
		pageVars:set('placementRecords.' .. prizePoolIndex, Json.stringify(_lpdb_stash))
	end

	return buildPrizePool
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	local lastStatuses = {
		CustomPrizePool._getStatusFromScore(lpdbData.lastscore),
		CustomPrizePool._getStatusFromScore(lpdbData.lastvsscore),
	}
	local extradata = {
		featured = Variables.varDefault('featured') or 'false',
		lastStatuses = lastStatuses,
		placeRange = {placement.placeStart, placement.placeEnd},
		playernumber = StarcraftOpponent.partySize(opponent.opponentData),
		points = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1),
		points2 = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 2),
		seriesnumber = seriesNumber and string.format('%05d', seriesNumber) or '',
		wofrom = lastStatuses[1] == WALKOVER_VS_STATUS or nil,
		woto = lastStatuses[2] == WALKOVER_VS_STATUS or nil,
	}

	-- make these available for the stash further down
	lpdbData.liquipediatier = _tier
	lpdbData.liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype')
	lpdbData.type = Variables.varDefault('tournament_type')

	lpdbData.weight = Weight.calc(
		lpdbData.individualprizemoney or 0,
		lpdbData.liquipediatier,
		lpdbData.placement,
		lpdbData.liquipediatiertype,
		lpdbData.type
	)

	if type(lpdbData.players) == 'table' then
		lpdbData.players = StarcraftOpponent.toLpdbStruct(opponent.opponentData).opponentplayers
	end

	if lpdbData.lastvs then
		local lastVs = opponent.additionalData.LASTVS
		extradata.vsOpponent = Table.deepCopy(lastVs)
		if lastVs.type == StarcraftOpponent.team then
			lpdbData.lastvs = Json.stringify{
				type = lastVs.opponenttype,
				name = lastVs.name
			}
		else
			lastVs = StarcraftOpponent.toLpdbStruct(lastVs) or {}
			lpdbData.lastvs = Json.stringify(Table.merge(
					lastVs.opponentplayers or {},
					{type = lastVs.opponenttype}
				))
		end
	end

	lpdbData.extradata = Table.mergeInto(lpdbData.extradata, extradata)

	lpdbData.mode = CustomPrizePool._getMode(opponent.opponenttype, opponent.opponentData)
	lpdbData.tournament = _tournament_name
	lpdbData.series = _series

	local prizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0
	if prizePoolIndex == 1 and _tournament_extradata_cache[lpdbData.placement or ''] then
		table.insert(_tournament_extradata_cache[lpdbData.placement], Table.deepCopy(lpdbData))
	end

	lpdbData.objectName = CustomPrizePool._overwriteObjectName(lpdbData, prizePoolIndex)
	lpdbData.id = lpdbData.objectName -- wanted for the stash

	table.insert(_lpdb_stash, Table.deepCopy(lpdbData))

	return lpdbData
end

function CustomPrizePool._overwriteObjectName(lpdbData, prizePoolIndex)
	if lpdbData.opponenttype == StarcraftOpponent.team then
		return lpdbData.objectName .. '_' .. prizePoolIndex
	end

	return lpdbData.objectName
end

function CustomPrizePool._getMode(opponentType, opponent)
	if (opponent or {}).isArchon then
		return 'archon'
	end

	return OPPONENT_TYPE_TO_MODE[opponentType or '']
end

function CustomPrizePool._getStatusFromScore(score)
	return Logic.isNumeric(score) and SCORE_STATUS or score
end

function CustomPrizePool._storeIntoTournamentLpdb()
	local tournamentName = Variables.varDefault('tournament_name', mw.title.getCurrentTitle().text)

	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))

	local extradata = {
		seriesNumber = seriesNumber and string.format('%05d', seriesNumber) or '',
		featured = Variables.varDefault('featured') or 'false'
	}

	for _, placement in pairs(_tournament_extradata_cache) do
		Table.mergeInto(
			extradata,
			CustomPrizePool._placementToTournamentExtradata(placement)
		)
	end

	mw.ext.LiquipediaDB.lpdb_tournament(
		'tournament_' .. tournamentName,
		{extradata = Json.stringify(extradata)}
	)
end

function CustomPrizePool._placementToTournamentExtradata(entries)
	if not entries[1] then
		return {}
	end

	local prefix = PLACE_TO_KEY_PREFIX[entries[1].placement]
	if (prefix and #entries > 1) or (not prefix and #entries > 2) then
		return {}
	end

	if not prefix then
		return Table.merge(
			CustomPrizePool._entryToTournamentExtradata(SEMIFINALS_PREFIX .. 1, entries[1]),
			CustomPrizePool._entryToTournamentExtradata(SEMIFINALS_PREFIX .. 1, entries[1])
		)
	end

	return CustomPrizePool._entryToTournamentExtradata(prefix, entries[1])
end

function CustomPrizePool._entryToTournamentExtradata(prefix, entry)
	local opponent = StarcraftOpponent.fromLpdbStruct{
		opponentplayers = entry.players or {},
		opponenttype = entry.opponenttype,
		opponentname = entry.participantlink,
		template = entry.participanttemplate,
	}

	local function toLink(player)
		return player.pageName
			and player.pageName .. '|' .. player.displayName
			or player.displayName
	end

	if opponent.type == StarcraftOpponent.solo then
		return {
			[prefix] = toLink(opponent.players[1]),
			[prefix .. 'flag'] = opponent.players[1].flag,
			[prefix .. 'link'] = opponent.players[1].pageName,
			[prefix .. 'race'] = opponent.players[1].race,
		}
	elseif StarcraftOpponent.typeIsParty(opponent.type) then
		local extradata = {}
		if opponent.isArchon then
			extradata[prefix .. 'race'] = opponent.players[1].race
		end
		for playerIndex, player in ipairs(opponent.players) do
			extradata[prefix .. 'p' .. playerIndex] = toLink(player)
			extradata[prefix .. 'flagp' .. playerIndex] = player.flag
			extradata[prefix .. 'linkp' .. playerIndex] = player.pageName
			extradata[prefix .. 'racep' .. playerIndex]
				= not opponent.isArchon and player.flag or nil
		end
		return extradata
	elseif opponent.type == StarcraftOpponent.team then
		return {[prefix] = opponent.name}
	end

	return {[prefix] = TBD}
end

function CustomSmwInjector:adjust(smwEntry, lpdbEntry)
	local extradata = Json.parseIfString(lpdbEntry.extradata) or {}
	local additionalCommonProps = {
		mode = lpdbEntry.mode,
		['has points'] = extradata.points,
		['has points2'] = extradata.points2,
		['has walkover from'] = extradata.wofrom and '1' or nil,
		['has walkover to'] = extradata.woto and '1' or nil,
	}

	-- fix lastvs opponent stuff
	if lpdbEntry.lastvs then
		local lastVs = extradata.vsOpponent or {}
		if lastVs.type == StarcraftOpponent.solo then
			smwEntry['has last opponent page'] = lastVs.players[1].pageName
			smwEntry['has last opponent'] = lastVs.players[1].displayName
		elseif StarcraftOpponent.typeIsParty(lastVs.type) then
			smwEntry['has last opponent'] = nil
			for playerIndex, player in ipairs(lastVs.players) do
				smwEntry['has last opponent ' .. playerIndex .. ' page'] = player.pageName
				smwEntry['has last opponent ' .. playerIndex] = player.displayName
			end
		elseif lastVs.type == StarcraftOpponent.team then
			smwEntry['has last opponent'] = lastVs.name
		end
	end

	return Table.merge(
		CustomPrizePool._opponentSmwProps(smwEntry, lpdbEntry),
		additionalCommonProps
	)
end

function CustomPrizePool._opponentSmwProps(smwEntry, lpdbData)
	if lpdbData.opponenttype == StarcraftOpponent.team or lpdbData.opponenttype == StarcraftOpponent.literal then
		return smwEntry
	elseif lpdbData.opponenttype == StarcraftOpponent.solo then
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

return CustomPrizePool
