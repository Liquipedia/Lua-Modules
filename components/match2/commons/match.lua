---
-- @Liquipedia
-- wiki=commons
-- page=Module:Match
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Error = require('Module:Error')
local ErrorStash = require('Module:Error/Stash')
local ErrorExt = require('Module:Error/Ext')
local FeatureFlag = require('Module:FeatureFlag')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')

local MatchGroupConfig = Lua.loadDataIfExists('Module:MatchGroup/Config')

local globalVars = PageVariableNamespace()

local Match = {}

function Match.storeFromArgs(frame)
	Match.store(Arguments.getArgs(frame))
end

function Match.toEncodedJson(frame)
	ErrorStash.deferDisplay()
	local args = Arguments.getArgs(frame)
	return Match._toEncodedJson(args)
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

function Match.storeMatchGroup(matchRecords, options)
	options = options or {}
	options = {
		bracketId = options.bracketId,
		storeMatch1 = Logic.nilOr(options.storeMatch1, true),
		storeMatch2 = Logic.nilOr(options.storeMatch2, true),
		storePageVar = Logic.nilOr(options.storePageVar, false),
		storeSmw = Logic.nilOr(options.storeSmw, true),
	}
	local LegacyMatch = (options.storeMatch1 or options.storeSmw) and Lua.requireIfExists('Module:Match/Legacy')

	local preparedMatchRecords, errors_ = ErrorExt.mapTry(matchRecords, function(matchRecord)
		local records = Match.splitRecordsByType(matchRecord)
		Match._prepareRecordsForStore(records)
		Match.populateSubobjectReferences(records)
		return records.matchRecord
	end)
	if #errors_ > 0 then
		local error = Match.summarizeErrors(errors_, 'Error preparing matches for storage.')
		ErrorExt.logAndStash(error)
	end

	-- Store matches in a page variable to bypass LPDB on the same page
	if options.storePageVar then
		assert(options.bracketId, 'Match.storeMatchGroup: Expect options.bracketId to specified')
		globalVars:set('match2bracket_' .. options.bracketId, Json.stringify(preparedMatchRecords))
		globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	end

	local matchRecordsCopy
	if LegacyMatch or options.storeMatch2 then
		matchRecordsCopy = Array.map(preparedMatchRecords, Match.copyRecords)
		Array.forEach(matchRecordsCopy, Match.encodeJson)
	end

	if options.storeMatch2 then
		local _, errors = ErrorExt.mapTry(matchRecordsCopy, function(matchRecord)
			local records
			if LegacyMatch then
				records = Match.splitRecordsByType(matchRecord)
				Match.populateSubobjectReferences(records)
			end
			Match._storeMatch2InLpdb(matchRecord)
			if LegacyMatch then
				Match.populateSubobjectReferences(records)
			end
		end)
		if #errors > 0 then
			local error = Match.summarizeErrors(errors, 'Error storing match2 records.')
			ErrorExt.logAndStash(error)
		end
	end

	if LegacyMatch then
		local _, errors = ErrorExt.mapTry(matchRecordsCopy, function(matchRecord)
			LegacyMatch.storeMatch(matchRecord, options)
		end)
		if #errors > 0 then
			local error = Match.summarizeErrors(errors, 'Error storing legacy match or SMW records.')
			ErrorExt.logAndStash(error)
		end
	end
end

--[[
Stores a single match from a match group. Used by standalone match pages.
]]
function Match.store(match, options)
	Match.storeMatchGroup({match}, type(options) == 'table' and options or nil)
end

--[[
Normalize references between a match record and its subobject records. For
instance, there are 3 ways each to connect to game records, opponent records,
and player records:

match.match2games (*)
match.games
match.mapX
match.match2opponents (*)
match.opponents
match.opponentX
opponent.match2players (*)
opponent.players
opponent.playerX

After Match.normalizeSubobjectReferences only the starred fields (*) will be present.
]]
function Match.normalizeSubobjectReferences(match)
	local records = Match.splitRecordsByType(match)
	Match.populateSubobjectReferences(records)
	return records.matchRecord
end

--[[
Groups subobjects by type (game, opponent, player), and removes direct
references between a match record and its subobject records.
]]
function Match.splitRecordsByType(match)
	local gameRecordList = Match._moveRecordsFromMatchToList(
		match,
		match.match2games or match.games or {},
		'map'
	)
	match.match2games = nil
	match.games = nil

	local opponentRecordList = Match._moveRecordsFromMatchToList(
		match,
		match.match2opponents or match.opponents or {},
		'opponent'
	)
	match.match2opponents = nil
	match.opponents = nil

	local playerRecordList = {}
	for opponentIndex, opponentRecord in ipairs(opponentRecordList) do
		table.insert(
			playerRecordList,
			Match._moveRecordsFromMatchToList(
				match,
				opponentRecord.match2players or opponentRecord.players or {},
				'opponent' .. opponentIndex .. '_p'
			)
		)
		opponentRecord.match2players = nil
		opponentRecord.players = nil
	end

	return {
		gameRecords = gameRecordList,
		matchRecord = match,
		opponentRecords = opponentRecordList,
		playerRecords = playerRecordList,
	}
end

--[[
	Moves the records found by iterating through `match` by `typePrefix`
	to `list`. Sets the original location (so in `match`) to `nil`.
]]
function Match._moveRecordsFromMatchToList(match, list, typePrefix)
	for key, item in Table.iter.pairsByPrefix(match, typePrefix) do
		match[key] = nil
		table.insert(list, item)
	end

	return list
end

--[[
Adds direct references between a match record and its subobjects. Specifically
it adds:

matchRecord.match2opponents
matchRecord.match2games
opponentRecord.match2players
]]
function Match.populateSubobjectReferences(records)
	local matchRecord = records.matchRecord
	matchRecord.match2opponents = records.opponentRecords
	matchRecord.match2games = records.gameRecords

	for opponentIndex, opponentRecord in ipairs(records.opponentRecords) do
		opponentRecord.match2players = records.playerRecords[opponentIndex]
	end
end

--[[
Partially deep copies a match by shallow copying the match records and and
subobject records, while copying the other objects like match.match2bracketdata
and opponent.extradata by reference. Assumes that subobject references have
been normalized (in Match.normalizeSubobjectReferences).
]]
function Match.copyRecords(matchRecord)
	return Table.merge(matchRecord, {
		match2opponents = Array.map(matchRecord.match2opponents, function(opponentRecord)
			return Table.merge(opponentRecord, {
				match2players = Array.map(opponentRecord.match2players, Table.copy)
			})
		end),
		match2games = Array.map(matchRecord.match2games, Table.copy),
	})
end

local function stringifyIfTable(tbl)
	return type(tbl) == 'table' and Json.stringify(tbl) or nil
end

function Match.encodeJson(matchRecord)
	matchRecord.match2bracketdata = stringifyIfTable(matchRecord.match2bracketdata)
	matchRecord.stream = stringifyIfTable(matchRecord.stream)
	matchRecord.links = stringifyIfTable(matchRecord.links)
	matchRecord.extradata = stringifyIfTable(matchRecord.extradata)

	for _, opponentRecord in ipairs(matchRecord.match2opponents) do
		opponentRecord.extradata = stringifyIfTable(opponentRecord.extradata)
		for _, playerRecord in ipairs(opponentRecord.match2players) do
			playerRecord.extradata = stringifyIfTable(playerRecord.extradata)
		end
	end
	for _, gameRecord in ipairs(matchRecord.match2games) do
		gameRecord.extradata = stringifyIfTable(gameRecord.extradata)
		gameRecord.participants = stringifyIfTable(gameRecord.participants)
		gameRecord.scores = stringifyIfTable(gameRecord.scores)
	end
end

function Match._storeMatch2InLpdb(unsplitMatchRecord)
	local records = Match.splitRecordsByType(unsplitMatchRecord)
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

--[[
Final processing of records before being stored to LPDB.
]]
function Match._prepareRecordsForStore(records)
	Match._prepareMatchRecordForStore(records.matchRecord)
	for opponentIndex, opponentRecord in ipairs(records.opponentRecords) do
		Match.clampFields(opponentRecord, Match.opponentFields)
		for _, playerRecord in ipairs(records.playerRecords[opponentIndex]) do
			Match.clampFields(playerRecord, Match.playerFields)
		end
	end
	for _, gameRecord in ipairs(records.gameRecords) do
		Match.clampFields(gameRecord, Match.gameFields)
	end
end

function Match._prepareMatchRecordForStore(match)
	match.dateexact = Logic.readBool(match.dateexact) and 1 or 0
	match.finished = Logic.readBool(match.finished) and 1 or 0
	match.match2bracketdata = match.match2bracketdata or match.bracketdata
	match.match2bracketid = match.match2bracketid or match.bracketid
	match.match2id = match.match2id or match.bracketid .. '_' .. match.matchid
	Match.clampFields(match, Match.matchFields)
end

Match.matchFields = Table.map({
	'bestof',
	'date',
	'dateexact',
	'extradata',
	'finished',
	'game',
	'icon',
	'icondark',
	'links',
	'liquipediatier',
	'liquipediatiertype',
	'lrthread',
	'match2bracketdata',
	'match2bracketid',
	'match2id',
	'mode',
	'parent',
	'parentname',
	'patch',
	'publishertier',
	'resulttype',
	'series',
	'shortname',
	'status',
	'stream',
	'tickername',
	'tournament',
	'type',
	'vod',
	'walkover',
	'winner',
}, function(_, field) return field, true end)

Match.opponentFields = Table.map({
	'extradata',
	'icon',
	'name',
	'placement',
	'score',
	'status',
	'template',
	'type',
}, function(_, field) return field, true end)

Match.playerFields = Table.map({
	'displayname',
	'extradata',
	'flag',
	'name',
}, function(_, field) return field, true end)

Match.gameFields = Table.map({
	'date',
	'extradata',
	'game',
	'length',
	'map',
	'mode',
	'participants',
	'resulttype',
	'rounds',
	'scores',
	'subgroup',
	'type',
	'vod',
	'walkover',
	'winner',
}, function(_, field) return field, true end)

function Match.clampFields(record, allowedKeys)
	for key, _ in pairs(record) do
		if not allowedKeys[key] then
			record[key] = nil
		end
	end
end

function Match.summarizeErrors(errors, messagePart)
	local function getMatchId(error)
		if type(error.elem) == 'string' then
			return error.elem
		elseif type(error.elem) == 'table' then
			return error.elem.match2id or error.elem.matchid
		else
			return 'unknown'
		end
	end

	local matchIds = Array.map(errors, getMatchId)
	local matchIdCutoff = 5
	local message = table.concat({
		messagePart,
		' Match IDs: ',
		table.concat(Array.sub(matchIds, 1, matchIdCutoff), ', '),
		#matchIds > matchIdCutoff and (', ... (' .. #matchIds .. ' total)') or '',
	})

	return Error{
		childErrors = errors,
		matchIds = matchIds,
		message = message,
		stacks = {debug.traceback()},
	}
end

-- Entry point from Template:TemplateMatch
function Match.templateFromMatchID(frame)
	local args = Arguments.getArgs(frame)
	local matchId = args[1] or 'match id is empty'
	return MatchGroupUtil.matchIdToKey(matchId)
end

if FeatureFlag.get('perf') then
	Match.perfConfig = Table.getByPathOrNil(MatchGroupConfig, {'subobjectPerf'})
	require('Module:Performance/Util').setupEntryPoints(Match, {'toEncodedJson'})
end

Lua.autoInvokeEntryPoints(Match, 'Module:Match', {'toEncodedJson'})

return Match
