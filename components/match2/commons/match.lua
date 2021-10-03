---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local FeatureFlag = require('Module:FeatureFlag')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local Table = require('Module:Table')

local Match = {}

function Match.storeFromArgs(frame)
	Match.store(Arguments.getArgs(frame))
end

function Match.toEncodedJson(frame)
	local args = Arguments.getArgs(frame)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local Match_ = Lua.import('Module:Match', {requireDevIfEnabled = true})
		return Match_.withPerformanceSetup(function()
			return Match_._toEncodedJson(args)
		end)
	end)
end

function Match._toEncodedJson(matchArgs)
	-- handle tbd and literals for opponents
	for opponentIndex = 1, matchArgs[1] or 2 do
		local opponent = matchArgs['opponent' .. opponentIndex]
		if Logic.isEmpty(opponent) then
			matchArgs['opponent' .. opponentIndex] = {
				type = 'literal', template = 'tbd', name = matchArgs['opponent' .. opponentIndex .. 'literal']
			}
		end
	end

	-- handle literals for qualifiers
	matchArgs.bracketdata = {
		qualwinLiteral = matchArgs.qualwinliteral,
		qualloseLiteral = matchArgs.qualloseliteral,
	}

	for key, map in Table.iter.pairsByPrefix(matchArgs, 'map') do
		matchArgs[key] = Json.parseIfString(map)
	end
	for key, opponent in Table.iter.pairsByPrefix(matchArgs, 'opponent') do
		matchArgs[key] = Json.parseIfString(opponent)
	end

	return Json.stringify(matchArgs)
end

function Match.store(match, options)
	options = options or {}
	options = {
		storeMatch1 = Logic.nilOr(options.storeMatch1, true),
		storeMatch2 = Logic.nilOr(options.storeMatch2, true),
		storeSmw = Logic.nilOr(options.storeSmw, true),
	}
	local records = match.matchRecord
		and match
		or Match.splitRecordsByType(match)
	Match.encodeRecords(records)

	-- Legacy match and SMW
	local LegacyMatch = (options.storeMatch1 or options.storeSmw) and Lua.requireIfExists('Module:Match/Legacy')
	if LegacyMatch then
		local records_ = Table.deepCopy(records)
		Match.populateEdges(records_)
		LegacyMatch.storeMatch(records_.matchRecord, options)
	end

	-- Match2
	if options.storeMatch2 then
		Match._storeMatch2(records)
	end
end

function Match.splitRecordsByType(match)
	local gameRecords = {}
	for _, gameRecord in Table.iter.pairsByPrefix(match, 'map') do
		table.insert(gameRecords, gameRecord)
	end

	local opponentRecords = {}
	local playerRecords = {}
	for opponentKey, opponentRecord in Table.iter.pairsByPrefix(match, 'opponent') do
		table.insert(opponentRecords, opponentRecord)
		table.insert(playerRecords, opponentRecord.match2players or {})
		for _, playerRecord in Table.iter.pairsByPrefix(match, opponentKey .. '_p') do
			table.insert(playerRecords[#playerRecords], playerRecord)
		end
	end

	return {
		gameRecords = gameRecords,
		matchRecord = Match.toMatchRecord(match),
		opponentRecords = opponentRecords,
		playerRecords = playerRecords,
	}
end

local function stringifyNonEmpty(tbl)
	return not Table.isEmpty(table)
		and Json.stringify(tbl)
		or nil
end

function Match.encodeRecords(records)
	local matchRecord = records.matchRecord
	matchRecord.match2bracketdata = stringifyNonEmpty(matchRecord.match2bracketdata)
	matchRecord.stream = stringifyNonEmpty(matchRecord.stream)
	matchRecord.links = stringifyNonEmpty(matchRecord.links)
	matchRecord.extradata = stringifyNonEmpty(matchRecord.extradata)

	for opponentIndex, opponentRecord in ipairs(records.opponentRecords) do
		opponentRecord.extradata = stringifyNonEmpty(opponentRecord.extradata)
		for _, playerRecord in ipairs(records.playerRecords[opponentIndex]) do
			playerRecord.extradata = stringifyNonEmpty(playerRecord.extradata)
		end
	end
	for _, gameRecord in ipairs(records.gameRecords) do
		gameRecord.extradata = stringifyNonEmpty(gameRecord.extradata)
		gameRecord.participants = stringifyNonEmpty(gameRecord.participants)
		gameRecord.scores = stringifyNonEmpty(gameRecord.scores)
	end
end

function Match.populateEdges(records)
	local matchRecord = records.matchRecord
	matchRecord.match2opponents = records.opponentRecords
	matchRecord.match2games = records.gameRecords

	for opponentIndex, opponentRecord in ipairs(records.opponentRecords) do
		opponentRecord.match2players = records.playerRecords[opponentIndex]
	end
end

function Match._storeMatch2(records)
	local matchRecord = records.matchRecord

	local opponentIndexes = Array.map(records.opponentRecords, function(opponentRecord, opponentIndex)
		local playerIndexes = Array.map(records.playerRecords[opponentIndex], function(player, playerIndex)
			return mw.ext.LiquipediaDB.lpdb_match2player(
				matchRecord.match2id .. '_m2o_' .. opponentIndex .. '_m2p_' .. playerIndex,
				player
			)
		end)

		opponentRecord.match2players = table.concat(playerIndexes)
		return mw.ext.LiquipediaDB.lpdb_match2opponent(
			matchRecord.match2id .. '_m2o_' .. opponentIndex,
			opponentRecord
		)
	end)

	local gameIndexes = Array.map(records.gameRecords, function(gameRecord, gameIndex)
		return mw.ext.LiquipediaDB.lpdb_match2game(
			matchRecord.match2id .. '_m2g_' .. gameIndex,
			gameRecord
		)
	end)

	matchRecord.match2games = table.concat(gameIndexes)
	matchRecord.match2opponents = table.concat(opponentIndexes)
	mw.ext.LiquipediaDB.lpdb_match2(matchRecord.match2id, matchRecord)
end

function Match.templateFromMatchID(frame)
	local args = Arguments.getArgs(frame)
	local matchId = args[1] or 'match id is empty'
	return MatchGroupUtil.matchIdToKey(matchId)
end

function Match.toMatchRecord(args)
	return {
		bestof = args.bestof,
		date = args.date,
		dateexact = Logic.readBool(args.dateexact) and 1 or 0,
		extradata = args.extradata,
		finished = Logic.readBool(args.finished) and 1 or 0,
		game = args.game,
		icon = args.icon,
		icondark = args.icondark,
		links = args.links,
		liquipediatier = args.liquipediatier,
		liquipediatiertype = args.liquipediatiertype,
		lrthread = args.lrthread,
		match2bracketdata = args.bracketdata or args.match2bracketdata,
		match2bracketid = args.bracketid,
		match2id = args.bracketid .. '_' .. args.matchid,
		mode = args.mode,
		parent = args.parent,
		parentname = args.parentname,
		patch = args.patch,
		publishertier = args.publishertier,
		resulttype = args.resulttype,
		series = args.series,
		shortname = args.shortname,
		status = args.status,
		stream = args.stream,
		tickername = args.tickername,
		tournament = args.tournament,
		type = args.type,
		vod = args.vod,
		walkover = args.walkover,
		winner = args.winner,
	}
end

function Match.withPerformanceSetup(f)
	if FeatureFlag.get('perf') then
		local matchGroupConfig = Lua.loadDataIfExists('Module:MatchGroup/Config')
		local perfConfig = Table.getByPathOrNil(matchGroupConfig, {'subobjectPerf'}) or {}
		return require('Module:Performance/Util').withSetup(perfConfig, f)
	else
		return f()
	end
end

return Match
