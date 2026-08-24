---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local TypeUtil = Lua.import('Module:TypeUtil')

--[[
Deprecated. The runtime TypeUtil description of the match group model, reachable as
MatchGroupUtil.types and extended by a couple of per wiki modules.

TypeUtil is on its way out, and the shapes themselves are documented as annotations on
Module:Domain/Match/Model and Module:Domain/Bracket/Model. Nothing new should be added here.
]]
local Types = {}

Types.LowerEdge = TypeUtil.struct({
	lowerMatchIndex = 'number',
	opponentIndex = 'number',
})
Types.AdvanceBg = TypeUtil.literalUnion('up', 'stayup', 'stay', 'staydown', 'down')

Types.AdvanceSpot = TypeUtil.struct({
	bg = Types.AdvanceBg,
	matchId = 'string?',
	type = TypeUtil.literalUnion('advance', 'custom', 'qualify'),
})

Types.BracketBracketData = TypeUtil.struct({
	advanceSpots = TypeUtil.array(Types.AdvanceSpot),
	bracketResetMatchId = 'string?',
	bracketType = 'string?',
	header = 'string?',
	inheritedHeader = 'string?',
	lowerEdges = TypeUtil.array(Types.LowerEdge),
	lowerMatchIds = TypeUtil.array('string'),
	qualLose = 'boolean?',
	qualLoseLiteral = 'string?',
	qualSkip = 'number?',
	qualWin = 'boolean?',
	qualifiedHeader = 'string?',
	qualWinLiteral = 'string?',
	skipRound = 'number?',
	thirdPlaceMatchId = 'string?',
	title = 'string?',
	type = TypeUtil.literal('bracket'),
	upperMatchId = 'string?',
})

Types.MatchCoordinates = TypeUtil.struct({
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

Types.MatchlistBracketData = TypeUtil.struct({
	header = 'string?',
	title = 'string?',
	dateHeader = 'boolean?',
	type = TypeUtil.literal('matchlist'),
})
Types.BracketData = TypeUtil.union(
	Types.MatchlistBracketData,
	Types.BracketBracketData
)

Types.Player = TypeUtil.struct({
	displayName = 'string?',
	flag = 'string?',
	pageName = 'string?',
	team = 'string?',
	extradata = 'table?',
	pageIsResolved = 'boolean?',
	faction = 'string?',
})

Types.Opponent = TypeUtil.struct({
	advanceBg = 'string?',
	advances = 'boolean?',
	icon = 'string?',
	name = 'string?',
	placement = 'number?',
	placement2 = 'number?',
	players = TypeUtil.array(Types.Player),
	score = 'number?',
	score2 = 'number?',
	status = 'string?',
	status2 = 'string?',
	template = 'string?',
	type = 'string',
	extradata = 'table',
})

Types.GameOpponent = TypeUtil.struct({
	name = 'string?',
	players = TypeUtil.optional(TypeUtil.array(Types.Player)),
	template = 'string?',
	type = 'string',
})

Types.Status = TypeUtil.optional(TypeUtil.literalUnion('notplayed', ''))

Types.Game = TypeUtil.struct({
	comment = 'string?',
	date = 'string?',
	game = 'string?',
	header = 'string?',
	length = TypeUtil.optional(TypeUtil.union('number', 'string')),
	map = 'string?',
	mapDisplayName = 'string?',
	mode = 'string?',
	patch = 'string?',
	resultType = 'string?',
	scores = TypeUtil.array('number'),
	subgroup = 'number?',
	type = 'string?',
	vod = 'string?',
	winner = 'number?',
	extradata = 'table?',
})

Types.Match = TypeUtil.struct({
	bracketData = Types.BracketData,
	comment = 'string?',
	date = 'string',
	dateIsExact = 'boolean',
	finished = 'boolean',
	game = 'string?',
	games = TypeUtil.array(Types.Game),
	icon = 'string?',
	iconDark = 'string?',
	links = 'table',
	liquipediatier = 'string?',
	liquipediatiertype = 'string?',
	matchId = 'string?',
	mode = 'string',
	opponents = TypeUtil.array(Types.Opponent),
	pageName = 'string?',
	parent = 'string?',
	patch = 'string?',
	publisherTier = 'string?',
	resultType = 'string?',
	section = 'string?',
	series = 'string?',
	shortname = 'string?',
	status = Types.Status,
	stream = 'table',
	tickername = 'string?',
	tournament = 'string?',
	type = 'string?',
	vod = 'string?',
	winner = 'number?',
	extradata = 'table?',
})

Types.Matchlist = TypeUtil.struct({
	bracketDatasById = TypeUtil.table('string', Types.BracketData),
	matches = TypeUtil.array(Types.Match),
	matchesById = TypeUtil.table('string', Types.Match),
	type = TypeUtil.literal('matchlist'),
})

Types.Bracket = TypeUtil.struct({
	bracketDatasById = TypeUtil.table('string', Types.BracketData),
	coordinatesByMatchId = TypeUtil.table('string', Types.MatchCoordinates),
	matches = TypeUtil.array(Types.Match),
	matchesById = TypeUtil.table('string', Types.Match),
	rootMatchIds = TypeUtil.array('string'),
	rounds = TypeUtil.array(TypeUtil.array('string')),
	sections = TypeUtil.array(TypeUtil.array('string')),
	type = TypeUtil.literal('bracket'),
})

Types.MatchGroup = TypeUtil.union(
	Types.Matchlist,
	Types.Bracket
)

return Types
