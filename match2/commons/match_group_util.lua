local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local TBD_DISPLAY = '<abbr title="To Be Decided">TBD</abbr>'

local nilIfEmpty = String.nilIfEmpty

--[[
Non-display utility functions for brackets, matchlists, matches, opponents,
games, and etc in the new bracket framework.

Display related functions go in Module:MatchGroup/Display/Helper.
]]
local MatchGroupUtil = {types = {}}

MatchGroupUtil.types.LowerMatch = TypeUtil.struct({
	matchId = 'string',
	opponentIx = 'number',
})
MatchGroupUtil.types.BracketBracketData = TypeUtil.struct({
	bracketResetMatchId = 'string?',
	bracketSection = 'string',
	header = 'string?',
	lowerMatches = TypeUtil.array(MatchGroupUtil.types.LowerMatch),
	qualLose = 'boolean?',
	qualLoseLiteral = 'string?',
	qualSkip = 'number?',
	qualWin = 'boolean?',
	qualWinLiteral = 'string?',
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
	date = 'string',
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

--[[
Fetches all matches in a matchlist or bracket. Tries to read from page
variables before fetching from LPDB. Returns a list of records
ordered lexicographically by matchId.
]]
function MatchGroupUtil.fetchMatchRecords(bracketId)
	local varData = Variables.varDefault("match2bracket_" .. bracketId)
	if varData then
		return Json.parse(varData)
	else
		return mw.ext.LiquipediaDB.lpdb(
			"match2",
			{
				conditions = "([[namespace::0]] or [[namespace::>0]]) AND [[match2bracketid::" .. bracketId .. "]]",
				order = "match2id ASC",
				limit = 5000,
			}
		)
	end
end

--[[
Fetches all matches in a matchlist or bracket. Returns a list of structurally
typed matches lexicographically ordered by matchId.
]]
MatchGroupUtil.fetchMatches = FnUtil.memoize(function(bracketId)
	return Array.map(
		MatchGroupUtil.fetchMatchRecords(bracketId),
		require('Module:Brkts/WikiSpecific').matchFromRecord
	)
end)

-- Returns a table whose entries are (matchId, match)
MatchGroupUtil.fetchMatchesTable = FnUtil.memoize(function(bracketId)
	local matches = MatchGroupUtil.fetchMatches(bracketId)
	local matchesById = {}
	for _, match in pairs(matches) do
		matchesById[match.matchId] = match
	end
	return matchesById
end)

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
	local extradata = Json.parseIfString(record.extradata) or {}
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
		local lowerMatches = {}
		local midIx = math.ceil(opponentCount / 2)
		if nilIfEmpty(data.toupper) then
			table.insert(lowerMatches, {
				matchId = data.toupper,
				opponentIx = midIx,
			})
		end
		if nilIfEmpty(data.tolower) then
			table.insert(lowerMatches, {
				matchId = data.tolower,
				opponentIx = math.min(midIx + 1, opponentCount),
			})
		end

		return {
			bracketResetMatchId = nilIfEmpty(data.bracketreset),
			bracketSection = data.bracketsection,
			header = nilIfEmpty(data.header),
			lowerMatches = lowerMatches,
			qualLose = Logic.readBool(data.quallose),
			qualLoseLiteral = nilIfEmpty(data.qualloseLiteral),
			qualSkip = tonumber(data.qualskip) or data.qualskip == 'true' and 1 or 0,
			qualWin = Logic.readBool(data.qualwin),
			qualWinLiteral = nilIfEmpty(data.qualwinLiteral),
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
	local extradata = Json.parseIfString(record.extradata) or {}
	return {
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
	local extradata = Json.parseIfString(record.extradata) or {}
	return {
		displayName = record.displayname,
		extradata = extradata,
		flag = nilIfEmpty(record.flag),
		pageName = record.name,
	}
end

function MatchGroupUtil.gameFromRecord(record)
	local extradata = Json.parseIfString(record.extradata) or {}
	return {
		comment = nilIfEmpty(Table.extract(extradata, 'comment')),
		date = record.date,
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

return MatchGroupUtil
