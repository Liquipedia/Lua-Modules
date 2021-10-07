---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')
local StringUtils = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')

local TBD_DISPLAY = '<abbr title="To Be Decided">TBD</abbr>'

local nilIfEmpty = StringUtils.nilIfEmpty

--[[
Non-display utility functions for brackets, matchlists, matches, opponents,
games, and etc in the new bracket framework.

Display related functions go in Module:MatchGroup/Display/Helper.
]]
local MatchGroupUtil = {types = {}}

MatchGroupUtil.types.LowerEdge = TypeUtil.struct({
	lowerMatchIx = 'number',
	opponentIx = 'number',
})
MatchGroupUtil.types.AdvanceBg = TypeUtil.literalUnion('up', 'stayup', 'stay', 'staydown', 'down')
MatchGroupUtil.types.AdvanceSpot = TypeUtil.struct({
	bg = MatchGroupUtil.types.AdvanceBg,
	matchId = 'string?',
	type = TypeUtil.literalUnion('advance', 'custom', 'qualify'),
})
MatchGroupUtil.types.BracketBracketData = TypeUtil.struct({
	advanceSpots = TypeUtil.array(MatchGroupUtil.types.AdvanceSpot),
	bracketResetMatchId = 'string?',
	header = 'string?',
	lowerEdges = TypeUtil.array(MatchGroupUtil.types.LowerEdge),
	lowerMatchIds = TypeUtil.array('string'),
	qualLose = 'boolean?',
	qualLoseLiteral = 'string?',
	qualSkip = 'number?',
	qualWin = 'boolean?',
	qualWinLiteral = 'string?',
	skipRound = 'number?',
	thirdPlaceMatchId = 'string?',
	title = 'string?',
	type = TypeUtil.literal('bracket'),
	upperMatchId = 'string?',
})
MatchGroupUtil.types.MatchCoordinates = TypeUtil.struct({
	depth = 'number',
	depthCount = 'number',
	matchIndexInRound = 'number',
	rootIndex = 'number',
	roundCount = 'number',
	roundIndex = 'number',
	sectionCount = 'number',
	sectionIndex = 'number',
	semanticDepth = 'number',
	semanticRoundIndex = 'number',
})
MatchGroupUtil.types.MatchlistBracketData = TypeUtil.struct({
	header = 'string?',
	title = 'string?',
	type = TypeUtil.literal('matchlist'),
})
MatchGroupUtil.types.BracketData = TypeUtil.union(
	MatchGroupUtil.types.MatchlistBracketData,
	MatchGroupUtil.types.BracketBracketData
)

MatchGroupUtil.types.Player = TypeUtil.struct({
	displayName = 'string?',
	flag = 'string?',
	pageName = 'string?',
})

MatchGroupUtil.types.Opponent = TypeUtil.struct({
	advanceBg = 'string?',
	advances = 'boolean?',
	icon = 'string?',
	name = 'string?',
	placement = 'number?',
	placement2 = 'number?',
	players = TypeUtil.array(MatchGroupUtil.types.Player),
	score = 'number?',
	score2 = 'number?',
	status = 'string?',
	status2 = 'string?',
	template = 'string?',
	type = 'string',
})

MatchGroupUtil.types.GameOpponent = TypeUtil.struct({
	name = 'string?',
	players = TypeUtil.optional(TypeUtil.array(MatchGroupUtil.types.Player)),
	template = 'string?',
	type = 'string',
})

MatchGroupUtil.types.ResultType = TypeUtil.literalUnion('default', 'draw', 'np')
MatchGroupUtil.types.Walkover = TypeUtil.literalUnion('L', 'FF', 'DQ')
MatchGroupUtil.types.Game = TypeUtil.struct({
	comment = 'string?',
	header = 'string?',
	length = 'number?',
	map = 'string?',
	mode = 'string?',
	participants = 'table',
	resultType = TypeUtil.optional(MatchGroupUtil.types.ResultType),
	scores = TypeUtil.array('number'),
	subgroup = 'number?',
	type = 'string?',
	vod = 'string?',
	walkover = TypeUtil.optional(MatchGroupUtil.types.Walkover),
	winner = 'number?',
})

MatchGroupUtil.types.Match = TypeUtil.struct({
	bracketData = MatchGroupUtil.types.BracketData,
	comment = 'string?',
	date = 'string',
	dateIsExact = 'boolean',
	finished = 'boolean',
	games = TypeUtil.array(MatchGroupUtil.types.Game),
	links = 'table',
	matchId = 'string?',
	mode = 'string',
	opponents = TypeUtil.array(MatchGroupUtil.types.Opponent),
	resultType = 'string?',
	stream = 'table',
	type = 'string?',
	vod = 'string?',
	walkover = 'string?',
	winner = 'number?',
})

MatchGroupUtil.types.Team = TypeUtil.struct({
	bracketName = 'string',
	displayName = 'string',
	pageName = 'string?',
	shortName = 'string',
})

MatchGroupUtil.types.MatchGroup = TypeUtil.struct({
	bracketDatasById = TypeUtil.table('string', MatchGroupUtil.types.BracketData),
	coordinatesByMatchId = TypeUtil.table('string', MatchGroupUtil.types.MatchCoordinates),
	matches = TypeUtil.array(MatchGroupUtil.types.Match),
	matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
	rootMatchIds = TypeUtil.array('string'),
	type = TypeUtil.literalUnion('matchlist, bracket'),
})

--[[
Fetches all matches in a matchlist or bracket. Tries to read from page
variables before fetching from LPDB. Returns a list of records
ordered lexicographically by matchId.
]]
function MatchGroupUtil.fetchMatchRecords(bracketId)
	local varData = Variables.varDefault('match2bracket_' .. bracketId)
	if varData then
		return Json.parse(varData)
	else
		local matchRecords = mw.ext.LiquipediaDB.lpdb(
			'match2',
			{
				conditions = '([[namespace::0]] or [[namespace::>0]]) AND [[match2bracketid::' .. bracketId .. ']]',
				order = 'match2id ASC',
				limit = 5000,
			}
		)
		for _, matchRecord in ipairs(matchRecords) do
			MatchGroupWorkaround.applyPlayerBugWorkaround(matchRecord)
		end
		return matchRecords
	end
end

MatchGroupUtil.fetchMatchGroup = FnUtil.memoize(function(bracketId)
	local matches = Array.map(
		MatchGroupUtil.fetchMatchRecords(bracketId),
		require('Module:Brkts/WikiSpecific').matchFromRecord
	)

	local matchesById = Table.map(matches, function(_, match) return match.matchId, match end)
	local bracketDatasById = Table.mapValues(matchesById, function(match) return match.bracketData end)

	MatchGroupUtil.populateMissingUpperMatchIds(bracketDatasById)

	local matchGroup = {
		bracketDatasById = bracketDatasById,
		coordinatesByMatchId = Table.mapValues(matchesById, function(match) return match.bracketData.coordinates end),
		matches = matches,
		matchesById = matchesById,
		rootMatchIds = MatchGroupUtil.computeRootMatchIds(matchesById),
		type = matches[1] and matches[1].bracketData.type or 'matchlist',
	}

	if matchGroup.type == 'bracket' then
		-- If coordinates is not populated (because the bracket template
		-- has not been purged), then compute a partial set of coordinates
		-- for use in displaying the bracket.
		if Table.isEmpty(matchGroup.coordinatesByMatchId) then
			MatchGroupUtil.populateMissingComputed(matchGroup)
		end

		MatchGroupUtil.populateAdvanceSpots(matchGroup)
	end

	return matchGroup
end)

--[[
Populate bracketData.upperMatchId, an field present on recently purged bracket
templates but missing from this bracket.
]]
function MatchGroupUtil.populateMissingUpperMatchIds(bracketDatasById)
	local _, bracketData1 = next(bracketDatasById)
	if bracketData1.type ~= 'bracket' or bracketData1.coordinates ~= nil then return end

	local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates', {requireDevIfEnabled = true})
	local upperMatchIds = MatchGroupCoordinates.computeUpperMatchIds(bracketDatasById)

	for matchId, bracketData in pairs(bracketDatasById) do
		bracketData.upperMatchId = upperMatchIds[matchId]
	end
end

--[[
Populate fields that are present on recently purged bracket templates but
missing from this bracket.
]]
function MatchGroupUtil.populateMissingComputed(matchGroup)
	if matchGroup.matches[1].bracketData.coordinates ~= nil then return end

	local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates', {requireDevIfEnabled = true})
	local bracketCoordinates = MatchGroupCoordinates.computeCoordinatesRestricted(matchGroup)

	matchGroup.coordinatesByMatchId = bracketCoordinates.coordinatesByMatchId
	for matchId, bracketData in pairs(matchGroup.bracketDatasById) do
		bracketData.coordinates = bracketCoordinates.coordinatesByMatchId[matchId]
	end
end

--[[
Fetches all matches in a matchlist or bracket. Returns a list of structurally
typed matches lexicographically ordered by matchId.
]]
function MatchGroupUtil.fetchMatches(bracketId)
	return MatchGroupUtil.fetchMatchGroup(bracketId).matches
end

--[[
Returns a match struct for use in a bracket display or match summary popup. The
bracket display and match summary popup expects that the finals match also
include results from the bracket reset match.
]]
function MatchGroupUtil.fetchMatchForBracketDisplay(bracketId, matchId)
	local bracket = MatchGroupUtil.fetchMatchGroup(bracketId)
	local match = bracket.matchesById[matchId]

	local bracketResetMatch = match
		and match.bracketData.bracketResetMatchId
		and bracket.matchesById[match.bracketData.bracketResetMatchId]
	if bracketResetMatch then
		return MatchGroupUtil.mergeBracketResetMatch(match, bracketResetMatch)
	else
		return match
	end
end

--[[
Converts a match record to a structurally typed table with the appropriate data
types for field values. The match record is either a match created in the store
bracket codepath (WikiSpecific.processMatch), or a record fetched from LPDB
(MatchGroupUtil.fetchMatchRecords). The returned match struct is used in
various display components (Bracket, MatchSummary, etc)

This is the implementation used on wikis by default. Wikis may specify a
different conversion by setting WikiSpecific.matchFromRecord. Refer
to the starcraft2 wiki as an example.
]]
function MatchGroupUtil.matchFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	local opponents = Array.map(record.match2opponents, MatchGroupUtil.opponentFromRecord)
	local bracketData = MatchGroupUtil.bracketDataFromRecord(Json.parseIfString(record.match2bracketdata))
	if bracketData.type == 'bracket' then
		bracketData.lowerEdges = bracketData.lowerEdges
			or MatchGroupUtil.autoAssignLowerEdges(#bracketData.lowerMatchIds, #opponents)
	end

	return {
		bracketData = bracketData,
		comment = nilIfEmpty(Table.extract(extradata, 'comment')),
		extradata = extradata,
		date = record.date,
		dateIsExact = Logic.readBool(record.dateexact),
		finished = Logic.readBool(record.finished),
		games = Array.map(record.match2games, MatchGroupUtil.gameFromRecord),
		links = Json.parseIfString(record.links) or {},
		matchId = record.match2id,
		mode = record.mode,
		opponents = opponents,
		resultType = nilIfEmpty(record.resulttype),
		stream = Json.parseIfString(record.stream) or {},
		type = nilIfEmpty(record.type) or 'literal',
		vod = nilIfEmpty(record.vod),
		walkover = nilIfEmpty(record.walkover),
		winner = tonumber(record.winner),
	}
end

function MatchGroupUtil.bracketDataFromRecord(data)
	if data.type == 'bracket' then
		local advanceSpots = data.advanceSpots or MatchGroupUtil.computeAdvanceSpots(data)
		return {
			advanceSpots = advanceSpots,
			bracketResetMatchId = nilIfEmpty(data.bracketreset),
			coordinates = data.coordinates and MatchGroupUtil.indexTableFromRecord(data.coordinates),
			header = nilIfEmpty(data.header),
			lowerEdges = data.lowerEdges and Array.map(data.lowerEdges, MatchGroupUtil.indexTableFromRecord),
			lowerMatchIds = data.lowerMatchIds or MatchGroupUtil.computeLowerMatchIdsFromLegacy(data),
			qualLose = advanceSpots[2] and advanceSpots[2].type == 'qualify',
			qualLoseLiteral = nilIfEmpty(data.qualloseLiteral),
			qualSkip = tonumber(data.qualskip) or data.qualskip == 'true' and 1 or 0,
			qualWin = advanceSpots[1] and advanceSpots[1].type == 'qualify',
			qualWinLiteral = nilIfEmpty(data.qualwinLiteral),
			skipRound = tonumber(data.skipround) or data.skipround == 'true' and 1 or 0,
			thirdPlaceMatchId = nilIfEmpty(data.thirdplace),
			type = 'bracket',
			upperMatchId = nilIfEmpty(data.upperMatchId),
		}
	else
		return {
			header = nilIfEmpty(data.header),
			title = nilIfEmpty(data.title),
			type = 'matchlist',
		}
	end
end

function MatchGroupUtil.bracketDataToRecord(bracketData)
	local coordinates = bracketData.coordinates
	local bracketsection = coordinates
		and MatchGroupUtil.sectionIndexToString(coordinates.sectionIndex, coordinates.sectionCount)
	return {
		bracketreset = bracketData.bracketResetMatchId,
		coordinates = coordinates and MatchGroupUtil.indexTableToRecord(coordinates),
		header = bracketData.header,
		lowerEdges = bracketData.lowerEdges and Array.map(bracketData.lowerEdges, MatchGroupUtil.indexTableToRecord),
		lowerMatchIds = bracketData.lowerMatchIds,
		qualWinLiteral = bracketData.qualwinLiteral,
		quallose = bracketData.qualLose and 'true' or nil,
		qualloseLiteral = bracketData.qualLoseLiteral,
		qualskip = bracketData.qualSkip ~= 0 and bracketData.qualSkip or nil,
		qualwin = bracketData.qualWin and 'true' or nil,
		skipround = bracketData.skipRound ~= 0 and bracketData.skipRound or nil,
		thirdplace = bracketData.thirdPlaceMatchId,
		type = bracketData.type,
		upperMatchId = bracketData.upperMatchId,

		-- Deprecated
		bracketsection = bracketsection,
		--rootIndex = coordinates.rootIndex,
		--tolower = bracketData.lowerMatchIds[#bracketData.lowerMatchIds],
		--toupper = bracketData.lowerMatchIds[#bracketData.lowerMatchIds - 1],
	}
end

function MatchGroupUtil.opponentFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	return {
		advanceBg = nilIfEmpty(Table.extract(extradata, 'bg')),
		advances = Logic.readBoolOrNil(Table.extract(extradata, 'advances')),
		extradata = extradata,
		icon = nilIfEmpty(record.icon),
		name = nilIfEmpty(record.name),
		placement = tonumber(record.placement),
		players = Array.map(record.match2players, MatchGroupUtil.playerFromRecord),
		score = tonumber(record.score),
		status = record.status,
		template = nilIfEmpty(record.template),
		type = nilIfEmpty(record.type) or 'literal',
	}
end

function MatchGroupUtil.createOpponent(args)
	return {
		extradata = args.extradata or {},
		icon = args.icon,
		name = args.name,
		placement = args.placement,
		players = args.players or {},
		score = args.score,
		status = args.status,
		template = args.template,
		type = args.type or 'literal',
	}
end

function MatchGroupUtil.playerFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	return {
		displayName = record.displayname,
		extradata = extradata,
		flag = nilIfEmpty(record.flag),
		pageName = record.name,
	}
end

function MatchGroupUtil.gameFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	return {
		comment = nilIfEmpty(Table.extract(extradata, 'comment')),
		extradata = extradata,
		header = nilIfEmpty(Table.extract(extradata, 'header')),
		length = tonumber(record.length),
		map = nilIfEmpty(record.map),
		mode = nilIfEmpty(record.mode),
		participants = Json.parseIfString(record.participants) or {},
		resultType = nilIfEmpty(record.resulttype),
		scores = Json.parseIfString(record.scores) or {},
		subgroup = tonumber(record.subgroup),
		type = nilIfEmpty(record.type),
		vod = nilIfEmpty(record.vod),
		walkover = nilIfEmpty(record.walkover),
		winner = tonumber(record.winner),
	}
end

function MatchGroupUtil.computeRootMatchIds(matchesById)
	-- Matches without upper matches
	local rootMatchIds = {}
	for matchId, match in pairs(matchesById) do
		if not match.bracketData.upperMatchId
			and not StringUtils.endsWith(matchId, 'RxMBR') then
			table.insert(rootMatchIds, matchId)
		end
	end

	Array.sortInPlaceBy(rootMatchIds, function(matchId)
		return {Table.getByPathOrNil(matchesById, {matchId, 'bracketData', 'coordinates','rootIndex'}) or -1, matchId}
	end)

	return rootMatchIds
end

function MatchGroupUtil.computeLowerMatchIdsFromLegacy(data)
	local lowerMatchIds = {}
	if nilIfEmpty(data.toupper) then
		table.insert(lowerMatchIds, data.toupper)
	end
	if nilIfEmpty(data.tolower) then
		table.insert(lowerMatchIds, data.tolower)
	end
	return lowerMatchIds
end

function MatchGroupUtil.autoAssignLowerEdges(lowerMatchCount, opponentCount)
	opponentCount = opponentCount or 2

	local lowerEdges = {}
	if lowerMatchCount <= opponentCount then
		local skip = math.ceil((opponentCount - lowerMatchCount) / 2)
		for lowerMatchIx = 1, lowerMatchCount do
			table.insert(lowerEdges, {
				lowerMatchIx = lowerMatchIx,
				opponentIx = lowerMatchIx + skip,
			})
		end
	else
		for lowerMatchIx = 1, lowerMatchCount do
			table.insert(lowerEdges, {
				lowerMatchIx = lowerMatchIx,
				opponentIx = math.min(lowerMatchIx, opponentCount),
			})
		end
	end
	return lowerEdges
end

--[[
Computes just the advance spots that can be determined from a match bracket
data. More are found in populateAdvanceSpots.
]]
function MatchGroupUtil.computeAdvanceSpots(data)
	local advanceSpots = {}

	if data.upperMatchId then
		advanceSpots[1] = {bg = 'up', type = 'advance', matchId = data.upperMatchId}
	end

	if nilIfEmpty(data.winnerto) then
		advanceSpots[1] = {bg = 'up', type = 'custom', matchId = data.winnerto}
	end
	if nilIfEmpty(data.loserto) then
		advanceSpots[2] = {bg = 'stayup', type = 'custom', matchId = data.loserto}
	end

	if Logic.readBool(data.qualwin) then
		advanceSpots[1] = Table.merge(advanceSpots[1], {bg = 'up', type = 'qualify'})
	end
	if Logic.readBool(data.quallose) then
		advanceSpots[2] = Table.merge(advanceSpots[2], {bg = 'stayup', type = 'qualify'})
	end

	return advanceSpots
end

function MatchGroupUtil.populateAdvanceSpots(bracket)
	if bracket.type ~= 'bracket' then
		return
	end

	-- Loser of semifinals play in third place match
	local firstBracketData = bracket.bracketDatasById[bracket.rootMatchIds[1]]
	local thirdPlaceMatchId = firstBracketData.thirdPlaceMatchId
	if thirdPlaceMatchId and bracket.matchesById[thirdPlaceMatchId] then
		for _, lowerMatchId in ipairs(firstBracketData.lowerMatchIds) do
			local bracketData = bracket.bracketDatasById[lowerMatchId]
			bracketData.advanceSpots[2] = bracketData.advanceSpots[2]
				or {bg = 'stayup', type = 'advance', matchId = thirdPlaceMatchId}
		end
	end

	-- Custom advance spots set via pbg params
	for _, match in ipairs(bracket.matches) do
		local pbgs = Array.mapIndexes(function(ix)
			return Table.extract(match.extradata, 'pbg' .. ix)
		end)
		for i = 1, #pbgs do
			match.bracketData.advanceSpots[i] = Table.merge(
				match.bracketData.advanceSpots[i],
				{bg = pbgs[i], type = 'custom'}
			)
		end
	end
end

-- Merges a grand finals match with results of its bracket reset match.
function MatchGroupUtil.mergeBracketResetMatch(match, bracketResetMatch)
	local mergedMatch = Table.merge(match, {
		opponents = {},
		games = Table.copy(match.games),
	})

	for ix, opponent in ipairs(match.opponents) do
		local resetOpponent = bracketResetMatch.opponents[ix]
		mergedMatch.opponents[ix] = Table.merge(opponent, {
			score2 = resetOpponent.score,
			status2 = resetOpponent.status,
			placement2 = resetOpponent.placement,
		})
	end

	for _, game in ipairs(bracketResetMatch.games) do
		table.insert(mergedMatch.games, game)
	end

	return mergedMatch
end

-- Convert 0-based indexes to 1-based
function MatchGroupUtil.indexTableFromRecord(record)
	return Table.map(record, function(key, value)
		if key:match('Index') or StringUtils.endsWith(key, 'Ix') then
			return key, value + 1
		else
			return key, value
		end
	end)
end

-- Convert 1-based indexes to 0-based
function MatchGroupUtil.indexTableToRecord(coordinates)
	return Table.map(coordinates, function(key, value)
		if key:match('Index') or StringUtils.endsWith(key, 'Ix') then
			return key, value - 1
		else
			return key, value
		end
	end)
end

-- Deprecated
function MatchGroupUtil.sectionIndexToString(sectionIndex, sectionCount)
	if sectionIndex == 1 then
		return 'upper'
	elseif sectionIndex == sectionCount then
		return 'lower'
	else
		return 'mid'
	end
end

--[[
Fetches information about a team via mw.ext.TeamTemplate.
]]
function MatchGroupUtil.fetchTeam(template)
	--exception for TBD opponents
	if string.lower(template) == 'tbd' then
		return {
			bracketName = TBD_DISPLAY,
			displayName = TBD_DISPLAY,
			pageName = 'TBD',
			shortName = TBD_DISPLAY,
		}
	end
	local rawTeam = mw.ext.TeamTemplate.raw(template)
	if not rawTeam then
		return nil
	end

	return {
		bracketName = rawTeam.bracketname,
		displayName = rawTeam.name,
		pageName = rawTeam.page,
		shortName = rawTeam.shortname,
	}
end

--[[
Parse extradata as a JSON string if read from page variables. Otherwise create
a copy if fetched from lpdb. The returned extradata table can then be mutated
without altering the source.
]]
function MatchGroupUtil.parseOrCopyExtradata(recordExtradata)
	return type(recordExtradata) == 'string' and Json.parse(recordExtradata)
		or type(recordExtradata) == 'table' and Table.copy(recordExtradata)
		or {}
end

--[[
Splits a matchId like h5HXaqbSVP_R02-M002 into the bracket ID h5HXaqbSVP and
the base match ID R02-M002.
]]
function MatchGroupUtil.splitMatchId(matchId)
	return matchId:match('^(.-)_([%w-]+)$')
end

--[[
Converts R01-M003 to R1M3
]]
function MatchGroupUtil.matchIdToKey(matchId)
	if matchId == 'RxMBR' or matchId == 'RxMTP' then
		return matchId
	end
	local round, matchInRound = matchId:match('^R(%d+)%-M(%d+)$')
	return 'R' .. tonumber(round) .. 'M' .. tonumber(matchInRound)
end

--[[
Converts R1M3 to R01-M003
]]
function MatchGroupUtil.matchIdFromKey(matchKey)
	if matchKey == 'RxMBR' or matchKey == 'RxMTP' then
		return matchKey
	end
	local round, matchInRound = matchKey:match('^R(%d+)M(%d+)$')
	return 'R' .. string.format('%02d', round) .. '-M' .. string.format('%03d', matchInRound)
end

return MatchGroupUtil
