---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:PrizePool/Custom
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
local Weight = require('Module:Weight')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})

local LpdbInjector = Lua.import('Module:Lpdb/Injector', {requireDevIfEnabled = true})
local StarcraftOpponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})

local globalVars = PageVariableNamespace{cached = true}
local pageVars = PageVariableNamespace('PrizePool')

local CustomLpdbInjector = Class.new(LpdbInjector)

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
local PLACE_TO_KEY_PREFIX = {'winner', 'runnerup', 'third', 'fourth'}
local SEMIFINALS_PREFIX = 'sf'
local TBD = 'TBD'

local _tournament_name
local _prize_pool_index
local _lpdb_prefix
local _placement_cache = {}
local _tournament_extradata_cache = {{}, {}, {}, {}, ['3-4'] = {}}

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

	-- set default lpdb_prefix as a hack to make TeamCards work ...
	_prize_pool_index = (tonumber(globalVars:get('prizepool_index')) or 0) + 1
	_lpdb_prefix = (args.lpdb_prefix or '') .. _prize_pool_index
	args.lpdb_prefix = _lpdb_prefix
	_tournament_name = args['tournament name']

	-- fixed setting
	args.resolveRedirect = true

	local prizePool = PrizePool(args):create()

	prizePool:setLpdbInjector(CustomLpdbInjector())

	local buildPrizePool = prizePool:build()

	--if _prize_pool_index == 1 and Logic.readBool(Logic.emptyOr(args.storeTournament, Namespace.isMain())) then
	if _prize_pool_index == 1 then
		CustomPrizePool._storeIntoTournamentLpdb()
	end

	pageVars:set('placementRecords.' .. _prize_pool_index, Json.stringify(_placement_cache))

	return buildPrizePool
end

function CustomLpdbInjector:adjust(lpdbData, placement, opponent)
	local seriesNumber = tonumber(globalVars:get('tournament_series_number'))
	local lastStatuses = {
		CustomPrizePool._getStatusFromScore(lpdbData.lastscore),
		CustomPrizePool._getStatusFromScore(lpdbData.lastvsscore),
	}
	local extradata = {
		featured = globalVars:get('featured') or 'false',
		lastStatuses = lastStatuses,
		placeRange = {placement.placeStart, placement.placeEnd},
		playernumber = StarcraftOpponent.partySize(opponent.opponentData),
		points = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 1),
		points2 = placement:getPrizeRewardForOpponent(opponent, PRIZE_TYPE_POINTS .. 2),
		seriesnumber = seriesNumber and string.format('%05d', seriesNumber) or '',
		wofrom = lastStatuses[1] == WALKOVER_VS_STATUS or nil,
		woto = lastStatuses[2] == WALKOVER_VS_STATUS or nil,
	}

	lpdbData.weight = Weight.calc(
		lpdbData.individualprizemoney or 0,
		globalVars:get('tournament_liquipediatier'),
		lpdbData.placement,
		globalVars:get('tournament_liquipediatiertype'),
		globalVars:get('tournament_type')
	)

	if type(lpdbData.players) == 'table' then
		lpdbData.players.type = lpdbData.opponenttype
	end

	if lpdbData.lastvs then
		local lastVs = (opponent.additionalData or {}).LASTVS
		extradata.vsOpponent = Json.stringify(lastVs)
		lastVs = StarcraftOpponent.toLpdbStruct(lastVs) or {}
		lpdbData.lastvs = Json.stringify(Table.merge(
				lastVs.opponentplayers or {},
				{type = lastVs.opponenttype}
			))
	end

	lpdbData.extradata = Table.mergeInto(lpdbData.extradata, extradata)

	lpdbData.mode = CustomPrizePool._getMode(opponent.opponenttype, opponent.opponentData)
	lpdbData.tournament = _tournament_name

	if _prize_pool_index == 1 and _tournament_extradata_cache[lpdbData.placement or ''] then
		table.insert(_tournament_extradata_cache[lpdbData.placement], Table.deepCopy(lpdbData))
	end

	-- store lpdbData as wiki-var for TeamCards
	-- ugly hack for now ...
	lpdbData.id = PrizePool:_lpdbObjectName(lpdbData, _prize_pool_index, _lpdb_prefix)
	table.insert(_placement_cache, Table.deepCopy(lpdbData))

	return lpdbData
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
	local tournamentName = globalVars:get('tournament_name') or mw.title.getCurrentTitle().text

	local seriesNumber = tonumber(globalVars:get('tournament_series_number'))

	local extradata = {
		seriesNumber = seriesNumber and string.format('%05d', seriesNumber) or '',
		featured = globalVars:get('featured') or 'false'
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

return CustomPrizePool
