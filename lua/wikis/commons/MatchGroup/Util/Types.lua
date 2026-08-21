---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local TypeUtil = Lua.import('Module:TypeUtil')

--[[
The shapes of the match group model: matches, opponents, games, players, bracket data and the
match groups that hold them.
]]
local Types = {}

---@class MatchGroupUtilLowerEdge
---@field lowerMatchIndex number
---@field opponentIndex number

Types.LowerEdge = TypeUtil.struct({
	lowerMatchIndex = 'number',
	opponentIndex = 'number',
})
---@alias AdvanceBg 'up'|'stayup'|'stay'|'staydown'|'down'
Types.AdvanceBg = TypeUtil.literalUnion('up', 'stayup', 'stay', 'staydown', 'down')
---@class MatchGroupUtilAdvanceSpot
---@field bg AdvanceBg
---@field matchId string?
---@field type string?

Types.AdvanceSpot = TypeUtil.struct({
	bg = Types.AdvanceBg,
	matchId = 'string?',
	type = TypeUtil.literalUnion('advance', 'custom', 'qualify'),
})

---@class MatchGroupUtilBracketBracketData
---@field coordinates MatchGroupUtilMatchCoordinates
---@field advanceSpots MatchGroupUtilAdvanceSpot[]
---@field bracketResetMatchId string?
---@field bracketType string?
---@field header string?
---@field inheritedHeader string?
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
---@field matchPage string?
---@field qualifiedHeader string?

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
---@class MatchGroupUtilMatchlistBracketData
---@field header string?
---@field title string?
---@field dateHeader boolean?
---@field type 'matchlist'
---@field matchId string?
---@field matchPage string?

Types.MatchlistBracketData = TypeUtil.struct({
	header = 'string?',
	title = 'string?',
	dateHeader = 'boolean?',
	type = TypeUtil.literal('matchlist'),
})
---@alias MatchGroupUtilBracketData MatchGroupUtilMatchlistBracketData|MatchGroupUtilBracketBracketData
Types.BracketData = TypeUtil.union(
	Types.MatchlistBracketData,
	Types.BracketBracketData
)

---@class standardPlayer
---@field displayName string?
---@field flag string?
---@field pageName string?
---@field team string?
---@field extradata table?
---@field pageIsResolved boolean?
---@field faction string?
---@field apiId string?

Types.Player = TypeUtil.struct({
	displayName = 'string?',
	flag = 'string?',
	pageName = 'string?',
	team = 'string?',
	extradata = 'table?',
	pageIsResolved = 'boolean?',
	faction = 'string?',
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
---@field scoreDisplay number?
---@field score2 number?
---@field status string?
---@field status2 string?
---@field template string?
---@field type OpponentType
---@field team string?
---@field extradata table

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

---@class GameOpponent
---@field name string?
---@field players standardPlayer[]
---@field template string?
---@field type string

Types.GameOpponent = TypeUtil.struct({
	name = 'string?',
	players = TypeUtil.optional(TypeUtil.array(Types.Player)),
	template = 'string?',
	type = 'string',
})

---@alias MatchStatus 'notplayed'|''|nil
Types.Status = TypeUtil.optional(TypeUtil.literalUnion('notplayed', ''))

---@class MatchGroupUtilGame
---@field comment string?
---@field date string?
---@field dateIsExact boolean
---@field game string?
---@field header string?
---@field length string|number?
---@field map string?
---@field mapDisplayName string?
---@field mode string?
---@field opponents {players: table[], score: number?, status: string?}[]
---@field patch string?
---@field resultType string?
---@field scores number[]
---@field subgroup number?
---@field type string?
---@field vod string?
---@field winner integer?
---@field status string?
---@field walkover string?
---@field extradata table?
---@field timestamp number
---@field timezoneId string?

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

---@class MatchGroupUtilMatch
---@field bracketData MatchGroupUtilBracketData
---@field comment string?
---@field date string
---@field dateIsExact boolean
---@field finished boolean
---@field game string?
---@field games MatchGroupUtilGame[]
---@field icon string?
---@field iconDark string?
---@field links table
---@field liquipediatier string? # TODO: camelCase
---@field liquipediatiertype string? # TODO: camelCase
---@field matchId string?
---@field mode string?
---@field opponents standardOpponent[]
---@field pageName string?
---@field parent string?
---@field patch string?
---@field phase 'upcoming'|'ongoing'|'finished'
---@field publisherTier string?
---@field resultType string?
---@field section string?
---@field series string?
---@field shortname string?
---@field status MatchStatus
---@field stream table
---@field tickername string?
---@field tournament string?
---@field type string?
---@field vod string?
---@field walkover string?
---@field winner number?
---@field extradata table?
---@field timestamp number
---@field timezoneId string?
---@field bestof number?

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

---@class MatchGroupUtilSubgroup
---@field games MatchGroupUtilGame[]
---@field subgroup number
---@field header string?

---@class FFAMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games FFAMatchGroupUtilGame[]

---@class FFAMatchGroupUtilGame: MatchGroupUtilGame
---@field stream table

---@class MatchGroupUtilMatchlist
---@field bracketDatasById table<string, MatchGroupUtilBracketBracketData>
---@field matches MatchGroupUtilMatch[]
---@field matchesById table<string, MatchGroupUtilMatch>
---@field type 'matchlist'

Types.Matchlist = TypeUtil.struct({
	bracketDatasById = TypeUtil.table('string', Types.BracketData),
	matches = TypeUtil.array(Types.Match),
	matchesById = TypeUtil.table('string', Types.Match),
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

---@alias MatchGroupUtilMatchGroup MatchGroupUtilBracket|MatchGroupUtilMatchlist
Types.MatchGroup = TypeUtil.union(
	Types.Matchlist,
	Types.Bracket
)

--- The subset of a match or game record that is enough to work out its phase.
---@class PartialMatchGameRecord
---@field date string
---@field dateexact boolean|string|nil # records carry '0'/'1'
---@field timestamp number?
---@field finished boolean?
---@field winner integer?

return Types
