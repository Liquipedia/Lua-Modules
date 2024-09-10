---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local StringUtils = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')

local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local TBD_DISPLAY = '<abbr title="To Be Decided">TBD</abbr>'
local NOW = os.time()

local nilIfEmpty = StringUtils.nilIfEmpty

--[[
Non-display utility functions for brackets, matchlists, matches, opponents,
games, and etc in the new bracket framework.

Display related functions go in Module:MatchGroup/Display/Helper.
]]
local MatchGroupUtil = {types = {}}

---@class MatchGroupUtilLowerEdge
---@field lowerMatchIndex number
---@field opponentIndex number
MatchGroupUtil.types.LowerEdge = TypeUtil.struct({
	lowerMatchIndex = 'number',
	opponentIndex = 'number',
})
---@alias AdvanceBg 'up'|'stayup'|'stay'|'staydown'|'down'
MatchGroupUtil.types.AdvanceBg = TypeUtil.literalUnion('up', 'stayup', 'stay', 'staydown', 'down')
---@class MatchGroupUtilAdvanceSpot
---@field bg AdvanceBg
---@field matchId string?
---@field type string?
MatchGroupUtil.types.AdvanceSpot = TypeUtil.struct({
	bg = MatchGroupUtil.types.AdvanceBg,
	matchId = 'string?',
	type = TypeUtil.literalUnion('advance', 'custom', 'qualify'),
})

---@class MatchGroupUtilBracketBracketData
---@field coordinates MatchGroupUtilMatchCoordinates
---@field advanceSpots MatchGroupUtilAdvanceSpot[]
---@field bracketResetMatchId string?
---@field header string?
---@field lowerEdges MatchGroupUtilLowerEdge[]?
---@field lowerMatchIds string[]
---@field qualLose boolean?
---@field qualLoseLiteral string?
---@field qualSkip number?
---@field qualWin boolean?
---@field qualWinLiteral string?
---@field skipRound number?
---@field thirdPlaceMatchId string?
---@field title string?
---@field type 'bracket'
---@field upperMatchId string?
---@field matchId string?
---@field qualifiedHeader boolean?
MatchGroupUtil.types.BracketBracketData = TypeUtil.struct({
	advanceSpots = TypeUtil.array(MatchGroupUtil.types.AdvanceSpot),
	bracketResetMatchId = 'string?',
	header = 'string?',
	inheritedHeader = 'string?',
	lowerEdges = TypeUtil.array(MatchGroupUtil.types.LowerEdge),
	lowerMatchIds = TypeUtil.array('string'),
	qualLose = 'boolean?',
	qualLoseLiteral = 'string?',
	qualSkip = 'number?',
	qualWin = 'boolean?',
	qualifiedHeader = 'boolean?',
	qualWinLiteral = 'string?',
	skipRound = 'number?',
	thirdPlaceMatchId = 'string?',
	title = 'string?',
	type = TypeUtil.literal('bracket'),
	upperMatchId = 'string?',
})
---@class MatchGroupUtilMatchCoordinates
---@field depth number
---@field depthCount number
---@field matchIndexInRound number
---@field rootIndex number
---@field roundCount number
---@field roundIndex number
---@field sectionCount number
---@field sectionIndex number
---@field semanticDepth number
---@field semanticRoundIndex number
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
---@class MatchGroupUtilMatchlistBracketData
---@field header string?
---@field title string?
---@field dateHeader boolean?
---@field type 'matchlist'
---@field matchId string?
MatchGroupUtil.types.MatchlistBracketData = TypeUtil.struct({
	header = 'string?',
	title = 'string?',
	dateHeader = 'boolean?',
	type = TypeUtil.literal('matchlist'),
})
---@alias MatchGroupUtilBracketData MatchGroupUtilMatchlistBracketData|MatchGroupUtilBracketBracketData
MatchGroupUtil.types.BracketData = TypeUtil.union(
	MatchGroupUtil.types.MatchlistBracketData,
	MatchGroupUtil.types.BracketBracketData
)

---@class standardPlayer
---@field displayName string?
---@field flag string?
---@field pageName string?
---@field team string?
---@field extradata table?
---@field pageIsResolved boolean?
MatchGroupUtil.types.Player = TypeUtil.struct({
	displayName = 'string?',
	flag = 'string?',
	pageName = 'string?',
	team = 'string?',
	extradata = 'table?',
})

---@class standardOpponent
---@field advanceBg string?
---@field advances boolean?
---@field icon string?
---@field icondark string?
---@field name string?
---@field placement number?
---@field placement2 number?
---@field players standardPlayer[]?
---@field score number?
---@field score2 number?
---@field status string?
---@field status2 string?
---@field template string?
---@field type OpponentType
---@field team string?
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

---@class GameOpponent
---@field name string?
---@field players standardPlayer[]
---@field template string?
---@field type string
MatchGroupUtil.types.GameOpponent = TypeUtil.struct({
	name = 'string?',
	players = TypeUtil.optional(TypeUtil.array(MatchGroupUtil.types.Player)),
	template = 'string?',
	type = 'string',
})

---@alias ResultType 'default'|'draw'|'np'
MatchGroupUtil.types.ResultType = TypeUtil.literalUnion('default', 'draw', 'np')
---@alias WalkoverType 'l'|'ff'|'dq'
MatchGroupUtil.types.Walkover = TypeUtil.literalUnion('l', 'ff', 'dq')

---@class MatchGroupUtilGame
---@field comment string?
---@field date string?
---@field game string?
---@field header string?
---@field length number?
---@field map string?
---@field mapDisplayName string?
---@field mode string?
---@field participants table
---@field resultType ResultType?
---@field scores number[]
---@field subgroup number?
---@field type string?
---@field vod string?
---@field walkover WalkoverType?
---@field winner integer?
---@field extradata table?
MatchGroupUtil.types.Game = TypeUtil.struct({
	comment = 'string?',
	date = 'string?',
	game = 'string?',
	header = 'string?',
	length = 'number?',
	map = 'string?',
	mapDisplayName = 'string?',
	mode = 'string?',
	participants = 'table',
	resultType = TypeUtil.optional(MatchGroupUtil.types.ResultType),
	scores = TypeUtil.array('number'),
	subgroup = 'number?',
	type = 'string?',
	vod = 'string?',
	walkover = TypeUtil.optional(MatchGroupUtil.types.Walkover),
	winner = 'number?',
	extradata = 'table?',
})

---@class MatchGroupUtilMatch
---@field bracketData MatchGroupUtilBracketData
---@field comment string?
---@field date string
---@field dateIsExact boolean
---@field finished boolean
---@field game string?
---@field games MatchGroupUtilGame[]
---@field links table
---@field matchId string?
---@field mode string?
---@field opponents standardOpponent[]
---@field resultType ResultType?
---@field stream table
---@field tickername string?
---@field tournament string?
---@field type string?
---@field vod string?
---@field walkover WalkoverType?
---@field winner string?
---@field extradata table?
---@field timestamp number
---@field bestof number?
MatchGroupUtil.types.Match = TypeUtil.struct({
	bracketData = MatchGroupUtil.types.BracketData,
	comment = 'string?',
	date = 'string',
	dateIsExact = 'boolean',
	finished = 'boolean',
	game = 'string?',
	games = TypeUtil.array(MatchGroupUtil.types.Game),
	links = 'table',
	matchId = 'string?',
	mode = 'string',
	opponents = TypeUtil.array(MatchGroupUtil.types.Opponent),
	resultType = 'string?',
	stream = 'table',
	tickername = 'string?',
	tournament = 'string?',
	type = 'string?',
	vod = 'string?',
	walkover = 'string?',
	winner = 'number?',
	extradata = 'table?',
})

---@class standardTeamProps
---@field bracketName string
---@field displayName string
---@field pageName string?
---@field shortName string
MatchGroupUtil.types.Team = TypeUtil.struct({
	bracketName = 'string',
	displayName = 'string',
	pageName = 'string?',
	shortName = 'string',
})

---@class MatchGroupUtilMatchlist
---@field bracketDatasById table<string, MatchGroupUtilBracketBracketData>
---@field matches MatchGroupUtilMatch[]
---@field matchesById table<string, MatchGroupUtilMatch>
---@field type 'matchlist'
MatchGroupUtil.types.Matchlist = TypeUtil.struct({
	bracketDatasById = TypeUtil.table('string', MatchGroupUtil.types.BracketData),
	matches = TypeUtil.array(MatchGroupUtil.types.Match),
	matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
	type = TypeUtil.literal('matchlist'),
})

---@class MatchGroupUtilBracket
---@field bracketDatasById table<string, MatchGroupUtilBracketBracketData>
---@field coordinatesByMatchId table<string, MatchGroupUtilMatchCoordinates>
---@field matches MatchGroupUtilMatch[]
---@field matchesById table<string, MatchGroupUtilMatch>
---@field rootMatchIds string[]
---@field rounds string[][]
---@field sections string[][]
---@field type 'bracket'
MatchGroupUtil.types.Bracket = TypeUtil.struct({
	bracketDatasById = TypeUtil.table('string', MatchGroupUtil.types.BracketData),
	coordinatesByMatchId = TypeUtil.table('string', MatchGroupUtil.types.MatchCoordinates),
	matches = TypeUtil.array(MatchGroupUtil.types.Match),
	matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
	rootMatchIds = TypeUtil.array('string'),
	rounds = TypeUtil.array(TypeUtil.array('string')),
	sections = TypeUtil.array(TypeUtil.array('string')),
	type = TypeUtil.literal('bracket'),
})

---@alias MatchGroupUtilMatchGroup MatchGroupUtilBracket|MatchGroupUtilMatchlist
MatchGroupUtil.types.MatchGroup = TypeUtil.union(
	MatchGroupUtil.types.Matchlist,
	MatchGroupUtil.types.Bracket
)

---Fetches all matches in a matchlist or bracket. Tries to read from page variables before fetching from LPDB.
---Returns a list of records ordered lexicographically by matchId.
---@param bracketId string
---@return table[]
function MatchGroupUtil.fetchMatchRecords(bracketId)
	local varData = Variables.varDefault('match2bracket_' .. bracketId)
	if varData then
		return (Json.parse(varData))
	end

	return mw.ext.LiquipediaDB.lpdb(
		'match2',
		{
			conditions = '([[namespace::0]] or [[namespace::>0]]) AND [[match2bracketid::' .. bracketId .. ']]',
			order = 'match2id ASC',
			limit = 5000,
		}
	)
end

MatchGroupUtil.fetchMatchGroup = FnUtil.memoize(function(bracketId)
	local matchRecords = MatchGroupUtil.fetchMatchRecords(bracketId)
	return MatchGroupUtil.makeMatchGroup(matchRecords)
end)

---Creates a match group structure from its match records. Returns a value of type MatchGroupUtil.types.MatchGroup.
---@param matchRecords table[]
---@return MatchGroupUtilMatchGroup
function MatchGroupUtil.makeMatchGroup(matchRecords)
	local type = matchRecords[1] and matchRecords[1].match2bracketdata.type or 'matchlist'
	if type == 'matchlist' then
		return MatchGroupUtil.makeMatchlistFromRecords(matchRecords)
	elseif type == 'bracket' then
		return MatchGroupUtil.makeBracketFromRecords(matchRecords)
	else
		error('Invalid match2bracketdata.type: ' .. type .. '. Expected matchlist or bracket.')
	end
end

---@param matchRecords table[]
---@return MatchGroupUtilMatchlist
function MatchGroupUtil.makeMatchlistFromRecords(matchRecords)
	local matches = Array.map(matchRecords, WikiSpecific.matchFromRecord)

	local matchesById = Table.map(matches, function(_, match) return match.matchId, match end)
	local bracketDatasById = Table.mapValues(matchesById, function(match) return match.bracketData end)

	return {
		bracketDatasById = bracketDatasById,
		matches = matches,
		matchesById = matchesById,
		type = 'matchlist',
	}
end

---@param matchRecords table[]
---@return MatchGroupUtilBracket
function MatchGroupUtil.makeBracketFromRecords(matchRecords)
	local matches = Array.map(matchRecords, WikiSpecific.matchFromRecord) --[[@as MatchGroupUtilMatch[] ]]

	local matchesById = Table.map(matches, function(_, match) return match.matchId, match end)
	local bracketDatasById = Table.mapValues(matchesById, function(match) return match.bracketData end)

	local firstCoordinates = matches[1] and matches[1].bracketData.coordinates
	if not firstCoordinates then
		MatchGroupUtil.backfillUpperMatchIds(bracketDatasById)
	end

	local bracket = {
		bracketDatasById = bracketDatasById,
		coordinatesByMatchId = Table.mapValues(matchesById, function(match) return match.bracketData.coordinates end),
		matches = matches,
		matchesById = matchesById,
		rootMatchIds = MatchGroupUtil.computeRootMatchIds(bracketDatasById),
		type = 'bracket',
	}

	if firstCoordinates then
		Table.mergeInto(bracket, {
			rounds = MatchGroupCoordinates.getRoundsFromCoordinates(bracket),
			sections = MatchGroupCoordinates.getSectionsFromCoordinates(bracket),
		})
	else
		MatchGroupUtil.backfillCoordinates(bracket)
	end

	MatchGroupUtil.populateAdvanceSpots(bracket)

	return bracket
end

---Returns an array of all the IDs of root matches. The matches are sorted in display order.
---@param bracketDatasById table<string, MatchGroupUtilBracketData>
---@return string[]
function MatchGroupUtil.computeRootMatchIds(bracketDatasById)
	-- Matches without upper matches
	local rootMatchIds = {}
	for matchId, bracketData in pairs(bracketDatasById) do
		if not bracketData.upperMatchId
			and not StringUtils.endsWith(matchId, 'RxMBR') then
			table.insert(rootMatchIds, matchId)
		end
	end

	Array.sortInPlaceBy(rootMatchIds, function(matchId)
		local coordinates = bracketDatasById[matchId].coordinates
		return coordinates and {coordinates.rootIndex} or {-1, matchId}
	end)

	return rootMatchIds
end

---Populate bracketData.upperMatchId if it is missing. This can happen if the bracket template is missing data.
---@param bracketDatasById table<string, MatchGroupUtilBracketData>
function MatchGroupUtil.backfillUpperMatchIds(bracketDatasById)
	local upperMatchIds = MatchGroupCoordinates.computeUpperMatchIds(bracketDatasById)

	for matchId, bracketData in pairs(bracketDatasById) do
		bracketData.upperMatchId = upperMatchIds[matchId]
	end
end

---Populate bracketData.coordinates if it is missing.
---This can happen if the bracket template has not been recently purged.
---@param matchGroup MatchGroupUtilBracket
function MatchGroupUtil.backfillCoordinates(matchGroup)
	local bracketCoordinates = MatchGroupCoordinates.computeCoordinates(matchGroup)

	Table.mergeInto(matchGroup, bracketCoordinates)
	for matchId, bracketData in pairs(matchGroup.bracketDatasById) do
		bracketData.coordinates = bracketCoordinates.coordinatesByMatchId[matchId]
	end
end

---Fetches all matches in a matchlist or bracket.
---Returns a list of structurally typed matches lexicographically ordered by matchId.
---@param bracketId string
---@return MatchGroupUtilMatch[]
function MatchGroupUtil.fetchMatches(bracketId)
	return MatchGroupUtil.fetchMatchGroup(bracketId).matches
end

---Returns a match struct for use in a bracket display or match summary popup. The bracket display and match summary
---popup expects that the finals match also include results from the bracket reset match.
---@param bracketId string
---@param matchId string
---@return MatchGroupUtilMatch, MatchGroupUtilMatch?
function MatchGroupUtil.fetchMatchForBracketDisplay(bracketId, matchId)
	local bracket = MatchGroupUtil.fetchMatchGroup(bracketId)
	local match = bracket.matchesById[matchId]

	local bracketResetMatch = match
		and match.bracketData.bracketResetMatchId
		and bracket.matchesById[match.bracketData.bracketResetMatchId]

	return match, bracketResetMatch
end

---Converts a match record to a structurally typed table with the appropriate data types for field values.
---The match record is either a match created in the store bracket codepath (WikiSpecific.processMatch),
---or a record fetched from LPDB (MatchGroupUtil.fetchMatchRecords).
---The returned match struct is used in various display components (Bracket, MatchSummary, etc)
---
---This is the implementation used on wikis by default. Wikis may specify a different conversion by setting
---WikiSpecific.matchFromRecord. Refer to the starcraft2 wiki as an example.
---@param record table
---@return MatchGroupUtilMatch
function MatchGroupUtil.matchFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	local opponents = Array.map(record.match2opponents, MatchGroupUtil.opponentFromRecord)
	local bracketData = MatchGroupUtil.bracketDataFromRecord(Json.parseIfString(record.match2bracketdata))
	if bracketData.type == 'bracket' then
		bracketData.lowerEdges = bracketData.lowerEdges
			or MatchGroupUtil.autoAssignLowerEdges(#bracketData.lowerMatchIds, #opponents)
	end

	local walkover = nilIfEmpty(record.walkover)

	return {
		bestof = tonumber(record.bestof) or 0,
		bracketData = bracketData,
		comment = nilIfEmpty(Table.extract(extradata, 'comment')),
		extradata = extradata,
		date = record.date,
		dateIsExact = Logic.readBool(record.dateexact),
		finished = Logic.readBool(record.finished),
		game = record.game,
		games = Array.map(record.match2games, MatchGroupUtil.gameFromRecord),
		links = Json.parseIfString(record.links) or {},
		matchId = record.match2id,
		liquipediatier = record.liquipediatier,
		liquipediatiertype = record.liquipediatiertype,
		mode = record.mode,
		opponents = opponents,
		parent = record.parent,
		patch = record.patch,
		resultType = nilIfEmpty(record.resulttype),
		stream = Json.parseIfString(record.stream) or {},
		tickername = record.tickername,
		timestamp = tonumber(Table.extract(extradata, 'timestamp')),
		tournament = record.tournament,
		type = nilIfEmpty(record.type) or 'literal',
		vod = nilIfEmpty(record.vod),
		walkover = walkover and walkover:lower() or nil,
		winner = tonumber(record.winner),
	}
end

---@param data table?
---@return MatchGroupUtilBracketData
function MatchGroupUtil.bracketDataFromRecord(data)
	if not data then
		return {}
	end
	if data.type == 'bracket' then
		local advanceSpots = data.advancespots or MatchGroupUtil.computeAdvanceSpots(data)
		return {
			advanceSpots = advanceSpots,
			bracketResetMatchId = nilIfEmpty(data.bracketreset),
			coordinates = data.coordinates and MatchGroupUtil.indexTableFromRecord(data.coordinates),
			header = nilIfEmpty(data.header),
			inheritedHeader = nilIfEmpty(data.inheritedheader),
			lowerEdges = data.loweredges and Array.map(data.loweredges, MatchGroupUtil.indexTableFromRecord),
			lowerMatchIds = data.lowerMatchIds or MatchGroupUtil.computeLowerMatchIdsFromLegacy(data),
			qualifiedHeader = nilIfEmpty(data.qualifiedheader),
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
			dateHeader = nilIfEmpty(data.dateheader),
			header = nilIfEmpty(data.header),
			inheritedHeader = nilIfEmpty(data.inheritedheader),
			matchIndex = nilIfEmpty(data.matchIndex),
			title = nilIfEmpty(data.title),
			type = 'matchlist',
		}
	end
end

---@param bracketData MatchGroupUtilBracketData
---@return table
function MatchGroupUtil.bracketDataToRecord(bracketData)
	local coordinates = bracketData.coordinates
	return {
		bracketreset = bracketData.bracketResetMatchId,
		bracketsection = coordinates
			and MatchGroupUtil.sectionIndexToString(coordinates.sectionIndex, coordinates.sectionCount),
		coordinates = coordinates and MatchGroupUtil.indexTableToRecord(coordinates),
		header = bracketData.header,
		lowerMatchIds = bracketData.lowerMatchIds,
		loweredges = bracketData.lowerEdges and Array.map(bracketData.lowerEdges, MatchGroupUtil.indexTableToRecord),
		quallose = bracketData.qualLose and 'true' or nil,
		qualloseLiteral = bracketData.qualLoseLiteral,
		qualskip = bracketData.qualSkip ~= 0 and bracketData.qualSkip or nil,
		qualwin = bracketData.qualWin and 'true' or nil,
		qualwinLiteral = bracketData.qualWinLiteral,
		skipround = bracketData.skipRound ~= 0 and bracketData.skipRound or nil,
		thirdplace = bracketData.thirdPlaceMatchId,
		tolower = bracketData.lowerMatchIds[#bracketData.lowerMatchIds],
		toupper = bracketData.lowerMatchIds[#bracketData.lowerMatchIds - 1],
		type = bracketData.type,
		upperMatchId = bracketData.upperMatchId,
	}
end

---@param record table
---@return standardOpponent
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

---@param args table
---@return table
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

---@param record table
---@return standardPlayer
function MatchGroupUtil.playerFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)
	return {
		displayName = record.displayname,
		extradata = extradata,
		flag = nilIfEmpty(record.flag),
		pageName = record.name,
	}
end

---@param record table
---@return MatchGroupUtilGame
function MatchGroupUtil.gameFromRecord(record)
	local extradata = MatchGroupUtil.parseOrCopyExtradata(record.extradata)

	local walkover = nilIfEmpty(record.walkover)

	return {
		comment = nilIfEmpty(Table.extract(extradata, 'comment')),
		date = record.date,
		extradata = extradata,
		game = record.game,
		header = nilIfEmpty(Table.extract(extradata, 'header')),
		length = record.length,
		map = nilIfEmpty(record.map),
		mapDisplayName = nilIfEmpty(Table.extract(extradata, 'displayname')),
		mode = nilIfEmpty(record.mode),
		participants = Json.parseIfString(record.participants) or {},
		resultType = nilIfEmpty(record.resulttype),
		scores = Json.parseIfString(record.scores) or {},
		subgroup = tonumber(record.subgroup),
		type = nilIfEmpty(record.type),
		vod = nilIfEmpty(record.vod),
		walkover = walkover and walkover:lower() or nil,
		winner = tonumber(record.winner),
	}
end

---@param data table
---@return string[]
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

---Auto compute lower edges, which encode the connector lines between lower matches and this match.
---@param lowerMatchCount integer
---@param opponentCount integer
---@return {lowerMatchIndex: integer, opponentIndex: integer}[]
function MatchGroupUtil.autoAssignLowerEdges(lowerMatchCount, opponentCount)
	local lowerEdges = {}
	if lowerMatchCount <= opponentCount then
		-- More opponents than lower matches: connect lower matches to opponents near the middle.
		local skip = math.ceil((opponentCount - lowerMatchCount) / 2)
		for lowerMatchIndex = 1, lowerMatchCount do
			table.insert(lowerEdges, {
				lowerMatchIndex = lowerMatchIndex,
				opponentIndex = lowerMatchIndex + skip,
			})
		end
	else
		-- More lower matches than opponents: The excess lower matches are all connected to the final opponent.
		for lowerMatchIndex = 1, lowerMatchCount do
			table.insert(lowerEdges, {
				lowerMatchIndex = lowerMatchIndex,
				opponentIndex = math.min(lowerMatchIndex, opponentCount),
			})
		end
	end
	return lowerEdges
end

---Computes just the advance spots that can be determined from a match bracket data.
---More are found in populateAdvanceSpots.
---@param data table
---@return table<1|2, {bg: string, type: string, matchId: string}>
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

---@param bracket MatchGroupUtilBracket
function MatchGroupUtil.populateAdvanceSpots(bracket)
	if #bracket.matches == 0 then
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

---Merges a grand finals match with results of its bracket reset match.
---@param match table
---@param bracketResetMatch table
---@return table
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

---Fetches information about a team via mw.ext.TeamTemplate.
---@param template string
---@return table?
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

---Parse extradata as a JSON string if read from page variables. Otherwise create a copy if fetched from lpdb.
---The returned extradata table can then be mutated without altering the source.
---@param recordExtradata table|string?
---@return table
function MatchGroupUtil.parseOrCopyExtradata(recordExtradata)
	return type(recordExtradata) == 'string' and Json.parse(recordExtradata)
		or type(recordExtradata) == 'table' and Table.copy(recordExtradata)
		or {}
end

---Convert 0-based indexes to 1-based
---@param record table
---@return table
function MatchGroupUtil.indexTableFromRecord(record)
	return Table.map(record, function(key, value)
		if key:match('Index') and type(value) == 'number' then
			return key, value + 1
		else
			return key, value
		end
	end)
end

---Convert 1-based indexes to 0-based
---@param coordinates table
---@return table
function MatchGroupUtil.indexTableToRecord(coordinates)
	return Table.map(coordinates, function(key, value)
		if key:match('Index') and type(value) == 'number' then
			return key, value - 1
		else
			return key, value
		end
	end)
end

---@param sectionIndex integer
---@param sectionCount integer
---@return string
function MatchGroupUtil.sectionIndexToString(sectionIndex, sectionCount)
	if sectionIndex == 1 then
		return 'upper'
	elseif sectionIndex == sectionCount then
		return 'lower'
	else
		return 'mid'
	end
end

---Splits a matchId like h5HXaqbSVP_R02-M002 into the bracket ID h5HXaqbSVP and the base match ID R02-M002.
---@param matchId string
---@return string?, string?
function MatchGroupUtil.splitMatchId(matchId)
	return matchId:match('^(.-)_([%w-]+)$')
end

---Converts R01-M003 to R1M3
---@param matchId string
---@return string
function MatchGroupUtil.matchIdToKey(matchId)
	if matchId == 'RxMBR' or matchId == 'RxMTP' then
		return matchId
	end
	local round, matchInRound = matchId:match('^R(%d+)%-M(%d+)$')
	return 'R' .. tonumber(round) .. 'M' .. tonumber(matchInRound)
end

---Converts R1M3 to R01-M003
---@param matchKey string
---@return string
function MatchGroupUtil.matchIdFromKey(matchKey)
	if matchKey == 'RxMBR' or matchKey == 'RxMTP' then
		return matchKey
	end
	local round, matchInRound = matchKey:match('^R(%d+)M(%d+)$')
	if round and matchInRound then
		-- Bracket format
		return 'R' .. string.format('%02d', round) .. '-M' .. string.format('%03d', matchInRound)
	else
		-- Matchlist format
		return string.format('%04d', matchKey)
	end
end

---@param matchid string?
---@param bracketid string?
---@return string?
function MatchGroupUtil.getStandaloneId(bracketid, matchid)
	if not matchid or not bracketid then
		return nil
	end
	return 'MATCH_' .. bracketid .. '_' .. matchid
end

---@class PartialMatchGameRecord
---@field date string
---@field dateexact boolean?
---@field timestamp number?
---@field finished boolean?
---@field winner integer?

---Determines the phase of a match based on its properties.
---@param match MatchGroupUtilMatch|MatchGroupUtilGame|PartialMatchGameRecord
---@return 'finished'|'ongoing'|'upcoming'
function MatchGroupUtil.computeMatchPhase(match)
	local isExact = Logic.readBoolOrNil(match.dateIsExact or match.dateexact)
	local matchStartTimestamp = match.timestamp or Date.readTimestampOrNil(match.date) or Date.defaultTimestamp
	if match.winner or Logic.readBool(match.finished) then
		return 'finished'
	elseif isExact ~= false and matchStartTimestamp ~= Date.defaultTimestamp and matchStartTimestamp <= NOW then
		return 'ongoing'
	else
		return 'upcoming'
	end
end

---Normalizes subtypes (opponent, map) into a list
---@param match table
---@param type 'opponent'|'map'
---@return any[]
function MatchGroupUtil.normalizeSubtype(match, type)
	local listNames
	if type == 'opponent' then
		listNames = {'match2opponents', 'opponents'}
	elseif type == 'map' then
		listNames = {'match2games', 'games'}
	else
		error('Invalid subtype: ' .. type)
	end
	for _, listName in ipairs(listNames) do
		if match[listName] then
			return match[listName]
		end
	end

	return Array.mapIndexes(function(index) return match[type .. index] end)
end

return MatchGroupUtil
