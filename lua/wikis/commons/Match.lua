---
-- @Liquipedia
-- page=Module:Match
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FeatureFlag = Lua.import('Module:FeatureFlag')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local MatchGroupConfig = Lua.requireIfExists('Module:MatchGroup/Config', {loadData = true})

-- These last_headings are considered sub headings
-- and matchsection should be used instead if available
local SUB_SECTIONS = {'high', 'mid', 'low'}

local globalVars = PageVariableNamespace()

---@class MatchStorage
local Match = {}

---@param frame Frame
function Match.storeFromArgs(frame)
	Match.store(Arguments.getArgs(frame))
end

---@param frame Frame
---@return string
function Match.toEncodedJson(frame)
	local args = Arguments.getArgs(frame)
	return Match.makeEncodedJson(args)
end

---@param matchArgs table
---@return string
function Match.makeEncodedJson(matchArgs)
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

---@param matchRecords table[]
---@param options {bracketId: string?, storeMatch1: string|boolean?, storeMatch2: string?, storePageVar: string?}?
function Match.storeMatchGroup(matchRecords, options)
	options = options or {}
	options = {
		bracketId = options.bracketId,
		storeMatch1 = Logic.nilOr(options.storeMatch1, true),
		storeMatch2 = Logic.nilOr(options.storeMatch2, true),
		storePageVar = Logic.nilOr(options.storePageVar, false),
	}
	local LegacyMatchConvert = Lua.requireIfExists('Module:Match/Legacy')
	local LegacyMatch = options.storeMatch1	and LegacyMatchConvert or nil

	local function prepareMatchRecords(matchRecord)
		local records = Match.splitRecordsByType(matchRecord)
		Match._prepareRecordsForStore(records)
		Match.populateSubobjectReferences(records)
		return records.matchRecord
	end
	local preparedMatchRecords = Array.map(matchRecords, Logic.wrapTryOrLog(prepareMatchRecords))

	-- Store matches in a page variable to bypass LPDB on the same page
	if options.storePageVar then
		assert(options.bracketId, 'Match.storeMatchGroup: Expect options.bracketId to specified')
		globalVars:set('match2bracket_' .. options.bracketId, Json.stringify(preparedMatchRecords))
		globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	end

	if not LegacyMatch and not options.storeMatch2 then
		return
	end

	local matchRecordsCopy = Array.map(preparedMatchRecords, Match.copyRecords)
	Array.forEach(matchRecordsCopy, Match.encodeJson)

	if options.storeMatch2 then
		local function storeMatch2(matchRecord)
			local records
			if LegacyMatch then
				records = Match.splitRecordsByType(matchRecord)
				Match.populateSubobjectReferences(records)
			end
			Match._storeMatch2InLpdb(matchRecord)
			if LegacyMatch then
				Match.populateSubobjectReferences(records)
			end
		end
		Array.forEach(matchRecordsCopy, Logic.wrapTryOrLog(storeMatch2))
	end

	if not LegacyMatch then
		return
	end
	Array.forEach(matchRecordsCopy, function(matchRecord)
		Logic.wrapTryOrLog(LegacyMatch.storeMatch)(matchRecord)
	end)
end

---Stores a single match from a match group. Used by standalone match pages.
---@param match table[]
---@param options {bracketId: string?, storeMatch1: string|boolean?, storeMatch2: string?, storePageVar: string?}?
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
---@param match table
---@return table
function Match.normalizeSubobjectReferences(match)
	local records = Match.splitRecordsByType(match)
	Match.populateSubobjectReferences(records)
	return records.matchRecord
end

---Groups subobjects by type (game, opponent, player),
---and removes direct references between a match record and its subobject records.
---@param match table
---@return {matchRecord: table, gameRecords: table[], opponentRecords: table[], playerRecords: table[]}
---@overload fun(match: any): {}
function Match.splitRecordsByType(match)
	if match == nil or type(match) ~= 'table' then
		return {}
	end

	local gameRecordList = MatchGroupUtil.normalizeSubtype(match, 'map')
	Match._removeLegacySubobjectRecords(match, 'map')
	match.match2games = nil
	match.games = nil

	local opponentRecordList = MatchGroupUtil.normalizeSubtype(match, 'opponent')
	Match._removeLegacySubobjectRecords(match, 'opponent')
	match.match2opponents = nil
	match.opponents = nil

	local playerRecordList = {}
	for opponentIndex, opponentRecord in ipairs(opponentRecordList) do
		if type(opponentRecord) ~= 'table' then
			break
		end

		table.insert(playerRecordList, opponentRecord.match2players or opponentRecord.players or {})
		Match._removeLegacySubobjectRecords(match, 'opponent' .. opponentIndex .. '_p')
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

---Sets the original location (so in `match`) to `nil` of suboject of a certain type.
---@param match table
---@param typePrefix string
function Match._removeLegacySubobjectRecords(match, typePrefix)
	for key in Table.iter.pairsByPrefix(match, typePrefix) do
		match[key] = nil
	end
end

--[[
Adds direct references between a match record and its subobjects. Specifically
it adds:

matchRecord.match2opponents
matchRecord.match2games
opponentRecord.match2players
]]
---@param records table
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
---@param matchRecord table
---@return table
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

---@param matchRecord table
function Match.encodeJson(matchRecord)
	matchRecord.match2bracketdata = Json.stringify(matchRecord.match2bracketdata, {asArray = true})
	matchRecord.stream = Json.stringify(matchRecord.stream)
	matchRecord.links = Json.stringify(matchRecord.links)
	matchRecord.extradata = Json.stringify(matchRecord.extradata)

	for _, opponentRecord in ipairs(matchRecord.match2opponents) do
		opponentRecord.extradata = Json.stringify(opponentRecord.extradata)
		for _, playerRecord in ipairs(opponentRecord.match2players) do
			playerRecord.extradata = Json.stringify(playerRecord.extradata)
		end
	end
	for _, gameRecord in ipairs(matchRecord.match2games) do
		gameRecord.extradata = Json.stringify(gameRecord.extradata)
		gameRecord.opponents = Json.stringify(gameRecord.opponents, {asArray = true})
		gameRecord.participants = Json.stringify(gameRecord.participants)
		gameRecord.scores = Json.stringify(gameRecord.scores, {asArray = true})
	end
end

---@param unsplitMatchRecord table
function Match._storeMatch2InLpdb(unsplitMatchRecord)
	local records = Match.splitRecordsByType(unsplitMatchRecord)
	local matchRecord = records.matchRecord

	local opponentIndexes = Array.map(records.opponentRecords, function(opponentRecord, opponentIndex)
		local playerIndexes = Array.map(records.playerRecords[opponentIndex], function(player, playerIndex)

			player.extradata = Logic.nilIfEmpty(player.extradata)

			return mw.ext.LiquipediaDB.lpdb_match2player(
				matchRecord.match2id .. '_m2o_' .. string.format('%02d', opponentIndex)
						.. '_m2p_' .. string.format('%02d', playerIndex),
				player
			)
		end)

		opponentRecord.extradata = Logic.nilIfEmpty(opponentRecord.extradata)

		opponentRecord.match2players = table.concat(playerIndexes)
		return mw.ext.LiquipediaDB.lpdb_match2opponent(
			matchRecord.match2id .. '_m2o_' .. string.format('%02d', opponentIndex),
			opponentRecord
		)
	end)

	local gameIndexes = Array.map(records.gameRecords, function(gameRecord, gameIndex)
		return mw.ext.LiquipediaDB.lpdb_match2game(
			matchRecord.match2id .. '_m2g_' .. string.format('%03d', gameIndex),
			gameRecord
		)
	end)

	matchRecord.match2games = table.concat(gameIndexes)
	matchRecord.match2opponents = table.concat(opponentIndexes)
	Lpdb.Match2:new(matchRecord):save()
end

---Final processing of records before being stored to LPDB.
---@param records table
function Match._prepareRecordsForStore(records)
	Match._prepareMatchRecordForStore(records.matchRecord, records.opponentRecords)
	for opponentIndex, opponentRecord in ipairs(records.opponentRecords) do
		Match.clampFields(opponentRecord, Match.opponentFields)
		for _, playerRecord in ipairs(records.playerRecords[opponentIndex]) do
			Match._preparePlayerRecordForStore(playerRecord)
		end
	end
	for _, gameRecord in ipairs(records.gameRecords) do
		Match._prepareGameRecordForStore(records.matchRecord, gameRecord)
	end
end

---@param match table
---@param opponents table[]?
function Match._prepareMatchRecordForStore(match, opponents)
	-- Backwards compatibility for API v3
	Match._commonBackwardsCompatabilityForV3API(match, opponents)

	match.dateexact = Logic.readBool(match.dateexact) and 1 or 0
	match.finished = Logic.readBool(match.finished) and 1 or 0
	match.match2bracketdata = match.match2bracketdata or match.bracketdata
	match.match2bracketid = match.match2bracketid or match.bracketid
	match.match2id = match.match2id or match.bracketid .. '_' .. match.matchid
	match.section = Match._getSection()
	match.extradata = Match._addCommonMatchExtradata(match)
	Match.clampFields(match, Match.matchFields)
end

---@param match table
---@return table
function Match._addCommonMatchExtradata(match)
	local commonExtradata = {
		comment = match.comment,
		matchsection = match.matchsection,
		timestamp = tonumber(match.timestamp),
		timezoneid = match.timezoneId,
		timezoneoffset = match.timezoneOffset,
	}

	return Table.merge(commonExtradata, match.extradata or {})
end

---@return string
function Match._getSection()
	---@param rawString string
	---@return string
	local cleanHtml = function(rawString)
		return (rawString:gsub('<.->', ''))
	end
	local lastHeading = cleanHtml(Variables.varDefault('last_heading', ''))
	local matchSection = cleanHtml(Variables.varDefault('matchsection', ''))
	if Logic.isNotEmpty(matchSection) and Table.includes(SUB_SECTIONS, lastHeading:lower()) then
		return matchSection
	end
	return lastHeading
end

---@param matchRecord table
---@param gameRecord table
function Match._prepareGameRecordForStore(matchRecord, gameRecord)
	-- Backwards compatibility for API v3
	Match._commonBackwardsCompatabilityForV3API(gameRecord, gameRecord.opponents)

	gameRecord.parent = matchRecord.parent
	gameRecord.tournament = matchRecord.tournament
	gameRecord.extradata = Match._addCommonGameExtradata(gameRecord)
	if not gameRecord.participants then
		gameRecord.participants = {}
		for opponentId, opponent in ipairs(gameRecord.opponents or {}) do
			for playerId, player in pairs(opponent.players or {}) do
				-- Deep copy have to be used here, otherwise a json.stringify complains about circular references
				-- between participants and opponents
				gameRecord.participants[opponentId .. '_' .. playerId] = Table.deepCopy(player)
			end
		end
	end
	Match.clampFields(gameRecord, Match.gameFields)
end

---@param game table
---@return table
function Match._addCommonGameExtradata(game)
	local commonExtradata = {
		comment = game.comment,
		dateexact = game.dateexact,
		timestamp = tonumber(game.timestamp),
		timezoneid = game.timezoneId,
		timezoneoffset = game.timezoneOffset,
	}

	return Table.merge(commonExtradata, game.extradata or {})
end

---@param playerRecord table
function Match._preparePlayerRecordForStore(playerRecord)
	playerRecord.extradata = playerRecord.extradata or {}
	playerRecord.extradata.playerteam = playerRecord.team
	Match.clampFields(playerRecord, Match.playerFields)
end

---Adds fields needed for backwards compatibility with API v3.
---walkover and resulttype are added to record.
---@param record table #game or match record
---@param opponents table[]? #opponents of the record
function Match._commonBackwardsCompatabilityForV3API(record, opponents)
	if record.finished then
		if not record.walkover then
			local function calculateWalkover()
				local walkoverOpponent = Array.find(opponents or {}, function(opponent)
					return opponent.status == 'FF' or opponent.status == 'DQ' or opponent.status == 'L'
				end)
				return walkoverOpponent and walkoverOpponent.status:lower() or ''
			end
			record.walkover = calculateWalkover()
		end

		if not record.resulttype then
			if record.status == 'notplayed' then
				record.resulttype = 'np'
			elseif record.winner == 0 then
				record.resulttype = 'draw'
			elseif record.walkover ~= '' then
				record.resulttype = 'default'
			else
				record.resulttype = ''
			end
		end
	end
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
	'match2bracketdata',
	'match2bracketid',
	'match2id',
	'mode',
	'parent',
	'parentname',
	'patch',
	'publishertier',
	'resulttype', -- LPDB API v3: backwards compatibility
	'series',
	'shortname',
	'status',
	'stream',
	'tickername',
	'tournament',
	'type',
	'vod',
	'walkover', -- LPDB API v3: backwards compatibility
	'winner',
	'section',
}, function(_, field) return field, true end)

Match.opponentFields = Table.map({
	'extradata',
	'icon',
	'icondark',
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
	'parent',
	'participants', -- LPDB API v3: backwards compatibility
	'patch',
	'opponents',
	'resulttype',  -- LPDB API v3: backwards compatibility
	'rounds',
	'scores', -- LPDB API v3: backwards compatibility
	'status',
	'subgroup',
	'tournament',
	'type',
	'vod',
	'walkover', -- LPDB API v3: backwards compatibility
	'winner',
}, function(_, field) return field, true end)

---@param record table
---@param allowedKeys table<string, boolean>
function Match.clampFields(record, allowedKeys)
	for key, _ in pairs(record) do
		if not allowedKeys[key] then
			record[key] = nil
		end
	end
end

if FeatureFlag.get('perf') then
	Match.perfConfig = Table.getByPathOrNil(MatchGroupConfig, {'subobjectPerf'})
end

return Match
