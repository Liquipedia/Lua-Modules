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
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')
local StringUtils = require('Module:StringUtils')
local Table = require('Module:Table')
local TreeUtil = require('Module:TreeUtil')
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
	lowerMatchIndex = 'number',
	opponentIndex = 'number',
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
	bracketSection = 'string',
	header = 'string?',
	lowerMatchIds = TypeUtil.array('string'),
	lowerEdges = TypeUtil.array(MatchGroupUtil.types.LowerEdge),
	qualLose = 'boolean?',
	qualLoseLiteral = 'string?',
	qualSkip = 'number?',
	qualWin = 'boolean?',
	qualWinLiteral = 'string?',
	rootIndex = 'number?',
	skipRound = 'number?',
	thirdPlaceMatchId = 'string?',
	title = 'string?',
	type = TypeUtil.literal('bracket'),
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
	rootMatchIds = TypeUtil.array('string'),
	matches = TypeUtil.array(MatchGroupUtil.types.Match),
	matchesById = TypeUtil.table('string', MatchGroupUtil.types.Match),
	type = TypeUtil.literalUnion('matchlist, bracket'),
	upperMatchIds = TypeUtil.table('string', 'string'),
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
	local upperMatchIds, rootMatchIds = MatchGroupUtil.computeUpperMatchIds(matchesById)
	local headMatchIds = Array.filter(
		rootMatchIds,
		function(matchId) return not StringUtils.endsWith(matchId, 'RxMTP')
	end)
	local matchGroup = {
		bracketDatasById = Table.mapValues(matchesById, function(match) return match.bracketData end),
		matches = matches,
		matchesById = matchesById,
		rootMatchIds = rootMatchIds,
		type = matches[1] and matches[1].bracketData.type or 'matchlist',
		upperMatchIds = upperMatchIds,
		headMatchIds = headMatchIds, --deprecated
	}

	if matchGroup.type == 'bracket' then
		local roundPropsByMatchId, rounds = MatchGroupUtil.computeRounds(matchGroup.bracketDatasById, rootMatchIds)

		MatchGroupUtil.populateAdvanceSpots(matchGroup)

		Table.mergeInto(matchGroup, {
			coordsByMatchId = roundPropsByMatchId,
			rounds = rounds,
		})
	end

	return matchGroup
end)

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

	return {
		bracketData = MatchGroupUtil.bracketDataFromRecord(Json.parseIfString(record.match2bracketdata), #opponents),
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

function MatchGroupUtil.bracketDataFromRecord(data, opponentCount)
	if data.type == 'bracket' then
		local lowerEdges = {}
		local lowerMatchIds = {}
		local midIx = math.floor(opponentCount / 2)
		if nilIfEmpty(data.toupper) then
			table.insert(lowerMatchIds, data.toupper)
			table.insert(lowerEdges, {
				opponentIndex = midIx,
				lowerMatchIndex = #lowerMatchIds,
			})
		end
		if nilIfEmpty(data.tolower) then
			table.insert(lowerMatchIds, data.tolower)
			table.insert(lowerEdges, {
				opponentIndex = math.min(midIx + 1, opponentCount),
				lowerMatchIndex = #lowerMatchIds,
			})
		end

		local advanceSpots = {}
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

		return {
			advanceSpots = advanceSpots,
			bracketResetMatchId = nilIfEmpty(data.bracketreset),
			bracketSection = data.bracketsection,
			header = nilIfEmpty(data.header),
			lowerEdges = lowerEdges,
			lowerMatchIds = lowerMatchIds,
			qualLose = advanceSpots[2] and advanceSpots[2].type == 'qualify',
			qualLoseLiteral = nilIfEmpty(data.qualloseLiteral),
			qualSkip = tonumber(data.qualskip) or data.qualskip == 'true' and 1 or 0,
			qualWin = advanceSpots[1] and advanceSpots[1].type == 'qualify',
			qualWinLiteral = nilIfEmpty(data.qualwinLiteral),
			rootIndex = tonumber(data.rootindex),
			skipRound = tonumber(data.skipround) or data.skipround == 'true' and 1 or 0,
			thirdPlaceMatchId = nilIfEmpty(data.thirdplace),
			type = 'bracket',
		}
	else
		return {
			header = nilIfEmpty(data.header),
			title = nilIfEmpty(data.title),
			type = 'matchlist',
		}
	end
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

function MatchGroupUtil.computeUpperMatchIds(matchesById)
	local upperMatchIds = {}
	for matchId, match in pairs(matchesById) do
		if match.bracketData.type == 'bracket' then
			for _, lowerMatchId in ipairs(match.bracketData.lowerMatchIds) do
				upperMatchIds[lowerMatchId] = matchId
			end
		end
	end

	-- Matches without upper matches
	local rootMatchIds = {}
	for matchId, _ in pairs(matchesById) do
		if not upperMatchIds[matchId]
			and not StringUtils.endsWith(matchId, 'RxMBR') then
			table.insert(rootMatchIds, matchId)
		end
	end

	-- Use custom ordering specified by rootIndex if present
	Array.sortInPlaceBy(rootMatchIds, function(matchId)
		return {matchesById[matchId].bracketData.rootIndex or -1, matchId}
	end)

	return upperMatchIds, rootMatchIds
end

function MatchGroupUtil.dfsFrom(bracketDatasById, start)
	return TreeUtil.dfs(
		function(matchId)
			return bracketDatasById[matchId].lowerMatchIds
		end,
		start
	)
end

function MatchGroupUtil.computeDepthsFrom(bracketDatasById, startMatchId)
	local depths = {}
	local maxDepth = -1
	local function visit(matchId, depth)
		local bracketData = bracketDatasById[matchId]
		depths[matchId] = depth
		maxDepth = math.max(maxDepth, depth + bracketData.skipRound)
		for _, lowerMatchId in ipairs(bracketData.lowerMatchIds) do
			visit(lowerMatchId, depth + 1 + bracketData.skipRound)
		end
	end
	visit(startMatchId, 0)
	return depths, maxDepth + 1
end

-- TODO store and read this from LPDB
function MatchGroupUtil.computeRounds(bracketDatasById, rootMatchIds)
	local rounds = {}
	local roundPropsByMatchId = {}
	for _, rootMatchId in ipairs(rootMatchIds) do
		local depths, depthCount = MatchGroupUtil.computeDepthsFrom(bracketDatasById, rootMatchId)
		for _ = #rounds + 1, depthCount do
			table.insert(rounds, {})
		end

		for matchId, depth in pairs(depths) do
			roundPropsByMatchId[matchId] = {
				depth = depth,
				depthCount = depthCount,
			}
		end
	end

	for rootIx, rootMatchId in ipairs(rootMatchIds) do
		for matchId in MatchGroupUtil.dfsFrom(bracketDatasById, rootMatchId) do
			local roundProps = roundPropsByMatchId[matchId]

			-- All roots are left aligned, except the third place match which is right aligned
			local roundIx = StringUtils.endsWith(matchId, 'RxMTP')
				and #rounds
				or roundProps.depthCount - roundProps.depth

			table.insert(rounds[roundIx], matchId)
			roundProps.matchIxInRound = #rounds[roundIx]
			roundProps.rootIx = rootIx
			roundProps.roundIx = roundIx
		end
	end

	return roundPropsByMatchId, rounds
end

function MatchGroupUtil.populateAdvanceSpots(bracket)
	if bracket.type ~= 'bracket' then
		return
	end

	-- Winner advances to upper match
	for _, match in ipairs(bracket.matches) do
		local upperMatchId = bracket.upperMatchIds[match.matchId]
		if upperMatchId then
			match.bracketData.advanceSpots[1] = match.bracketData.advanceSpots[1]
				or {bg = 'up', type = 'advance', matchId = upperMatchId}
		end
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
