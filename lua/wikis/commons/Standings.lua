---
-- @Liquipedia
-- page=Module:Standings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Lpdb = Lua.import('Module:Lpdb')
local Namespace = Lua.import('Module:Namespace')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local Tournament = Lua.import('Module:Tournament')

local Opponent = Lua.import('Module:Opponent/Custom')
local StandingsStorage = Lua.import('Module:Standings/Storage')

local Standings = {}

---@class StandingsModel
---@field namespace integer
---@field pageName string
---@field standingsIndex integer
---@field tournament StandardTournament?
---@field title string?
---@field section string?
---@field type StandingsTableTypes
---@field matches MatchGroupUtilMatch[]
---@field config {hasdraws: boolean?, hasovertime: boolean?, haspoints: boolean?}
---@field rounds StandingsRound[]
---@field additionalStats StandingsAdditionalStat[]
---@field package record standingstable
---@field package entryRecords standingsentry[]

---@class StandingsAdditionalStat
---@field id string
---@field title string? # Stats without a title get no column
---@field tiebreaker boolean? # Whether the stat is one of the tiebreakers, otherwise it is only shown

---@class StandingsRound
---@field round integer
---@field started boolean
---@field finished boolean
---@field title string
---@field opponents StandingsEntryModel[]

---@class StandingsEntryModel
---@field opponent standardOpponent
---@field placement string
---@field position integer
---@field points number
---@field matchWins integer
---@field matchLosses integer
---@field positionStatus string?
---@field definitiveStatus string?
---@field match MatchGroupUtilMatch?
---@field matchOpponentIndex integer? # Index of the opponent in `match`, needed as the match is not alias resolved
---@field positionChangeFromPreviousRound integer
---@field pointsChangeFromPreviousRound number
---@field specialStatus 'dq'|'nc'|'' # nc = non-competing (not in the round)
---@field disqualified boolean
---@field additionalStatsValues table<string, {value: StandingsTiebreakerValue?, display: string?}>
---@field package matchId string?

---Fetches a standings table of a page from LPDB.
---@param pagename string
---@param standingsIndex integer #0-index'd on per page
---@return StandingsModel?
function Standings.getStandingsTable(pagename, standingsIndex)
	local namespaceName, basePageName = Page.splitPageName(Page.pageifyLink(pagename))

	local record = mw.ext.LiquipediaDB.lpdb('standingstable', {
		conditions = tostring(Condition.Tree(Condition.BooleanOperator.all):add{
			Condition.Node(Condition.ColumnName('pagename'), Condition.Comparator.eq, basePageName:gsub(' ', '_')),
			Condition.Node(Condition.ColumnName('standingsindex'), Condition.Comparator.eq, standingsIndex),
			Condition.Node(Condition.ColumnName('namespace'), Condition.Comparator.eq, Namespace.idFromName(namespaceName)),
		}),
		limit = 1,
	})[1]
	if not record then
		return nil
	end
	return Standings.standingsFromRecord(record)
end

local StandingsMT = {
	__index = function(standings, property)
		if property == 'tournament' then
			standings[property] = Tournament.getTournament(standings.pageName)
		elseif property == 'matches' then
			standings[property] = Standings.fetchMatches(standings)
		elseif property == 'rounds' then
			standings[property] = Standings.makeRounds(standings)
		elseif property == 'entryRecords' then
			standings[property] = Standings.fetchEntries(standings)
		end
		return rawget(standings, property)
	end
}

local StandingsEntryMT = {
	__index = function(entry, property)
		if property == 'match' then
			entry[property] = Standings.fetchMatch(entry)
		end
		return rawget(entry, property)
	end
}

---@param record standingstable
---@param entries standingsentry[]?
---@return StandingsModel
function Standings.standingsFromRecord(record, entries)
	local standings = {
		namespace = record.namespace,
		pageName = record.pagename,
		standingsIndex = record.standingsindex,
		title = record.title,
		section = record.section,
		type = StandingsStorage.fromStorageType(record.type),
		config = record.config,
		additionalStats = record.extradata.additionalStats,
		record = record,
		entryRecords = entries,
	}

	-- Some properties are derived from other properties and we can calculate them when accessed.
	setmetatable(standings, StandingsMT)

	return standings
end

---@param record standingsentry
---@return StandingsEntryModel
function Standings.entryFromRecord(record)
	local entry = {
		opponent = Opponent.fromLpdbStruct(record),
		placement = record.placement,
		position = tonumber(record.slotindex),
		positionStatus = record.currentstatus,
		definitiveStatus = record.definitestatus,
		points = record.scoreboard.points,
		matchWins = record.scoreboard.match.w,
		matchLosses = record.scoreboard.match.l,
		pointsChangeFromPreviousRound = record.extradata.pointschange,
		specialStatus = record.extradata.specialstatus or '',
		disqualified = record.extradata.disqualified == true,
		positionChangeFromPreviousRound = tonumber(record.placementchange),
		additionalStatsValues = record.extradata.additionalStatsValues or {},
		matchOpponentIndex = tonumber(record.extradata.matchopponentindex),
		matchId = record.extradata.matchid,
	}

	-- Some properties are derived from other properties and we can calculate them when accessed.
	setmetatable(entry, StandingsEntryMT)

	return entry
end

---@param standings StandingsModel
---@return MatchGroupUtilMatch[]
function Standings.fetchMatches(standings)
	local matchids = Json.parseIfString(standings.record.matches) or {}
	local bracketIds = Array.unique(Array.map(matchids, function(matchid)
		return MatchGroupUtil.splitMatchId(matchid)
	end))

	local wantedMatchIds = Table.map(matchids, function(_, matchid) return matchid, true end)
	local allMatchesFromBrackets = Array.flatMap(bracketIds, MatchGroupUtil.fetchMatches)
	return Array.filter(allMatchesFromBrackets, function(match)
		return wantedMatchIds[match.matchId]
	end)
end

---@param entry StandingsEntryModel
---@return MatchGroupUtilMatch?
function Standings.fetchMatch(entry)
	local matchid = entry.matchId
	if not matchid then
		return
	end
	local bracketId = MatchGroupUtil.splitMatchId(matchid)
	if not bracketId then
		return
	end

	return MatchGroupUtil.fetchMatchGroup(bracketId).matchesById[matchid]
end

---@param standings StandingsModel
---@return standingsentry[]
function Standings.fetchEntries(standings)
	local standingsEntries = {}
	local conditions = Condition.Tree(Condition.BooleanOperator.all):add{
		Condition.Node(Condition.ColumnName('namespace'), Condition.Comparator.eq, standings.namespace),
		Condition.Node(Condition.ColumnName('pagename'), Condition.Comparator.eq, standings.pageName),
		Condition.Node(Condition.ColumnName('standingsindex'), Condition.Comparator.eq, standings.standingsIndex),
	}

	Lpdb.executeMassQuery(
		'standingsentry',
		{
			conditions = conditions:toString(),
			order = 'roundindex asc',
		},
		function(record)
			table.insert(standingsEntries, record)
		end
	)
	return standingsEntries
end

---@param standings StandingsModel
---@return StandingsRound[]
function Standings.makeRounds(standings)
	local record = standings.record
	local standingsEntries = standings.entryRecords
	-- Release each record once its entry is built
	standings.entryRecords = {}

	local roundCount = Array.maxBy(Array.map(standingsEntries, function(entry)
		return tonumber(entry.roundindex) or 1 end), FnUtil.identity)

	---@type table<integer, StandingsEntryModel[]>
	local entriesByRound = {}
	for index, entryRecord in ipairs(standingsEntries) do
		local roundIndex = tonumber(entryRecord.roundindex)
		if roundIndex then
			entriesByRound[roundIndex] = entriesByRound[roundIndex] or {}
			table.insert(entriesByRound[roundIndex], Standings.entryFromRecord(entryRecord))
		end
		standingsEntries[index] = nil
	end

	return Array.mapRange(1, roundCount or 1, function(roundIndex)
		local opponents = entriesByRound[roundIndex] or {}
		Array.sortInPlaceBy(opponents, Operator.property('position'))
		return {
			round = roundIndex,
			opponents = opponents,
			finished = (record.extradata.rounds[roundIndex] or {}).finished or false,
			started = (record.extradata.rounds[roundIndex] or {}).started or false,
			title = (record.extradata.rounds[roundIndex] or {}).title or ('Round ' .. roundIndex),
		}
	end)
end

return Standings
