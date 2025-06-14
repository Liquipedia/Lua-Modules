---
-- @Liquipedia
-- page=Module:Standings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Condition = require('Module:Condition')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local Tournament = Lua.import('Module:Tournament')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local Standings = {}

---@class StandingsModel
---@field pageName string
---@field standingsIndex integer
---@field tournament StandardTournament?
---@field title string?
---@field section string?
---@field type 'ffa'|'swiss'|'league'
---@field matches MatchGroupUtilMatch[]
---@field config table
---@field rounds StandingsRound[]
---@field private record standingstable
---@field private entryRecords standingsentry[]

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
---@field positionChangeFromPreviousRound integer
---@field pointsChangeFromPreviousRound number
---@field specialStatus 'dq'|'nc'|'' # nc = non-competing (not in the round)
---@field private record standingstable

---Fetches a standings table from a page. Tries to read from page variables before fetching from LPDB.
---@param pagename string
---@param standingsIndex integer #0-index'd on per page
---@return StandingsModel?
function Standings.getStandingsTable(pagename, standingsIndex)
	local pageNameInCorrectFormat = string.gsub(pagename, ' ', '_')
	local myPageName = string.gsub(mw.title.getCurrentTitle().text, ' ', '_')

	if pageNameInCorrectFormat == myPageName then
		local varData = Variables.varDefault('standings2_' .. standingsIndex)
		if varData then
			local standings = Json.parseStringified(varData)
			return Standings.standingsFromRecord(standings.standings, standings.entries)
		end
	end

	local record = mw.ext.LiquipediaDB.lpdb('standingstable', {
		conditions = '[[pagename::' .. pageNameInCorrectFormat .. ']] AND [[standingsindex::' .. standingsIndex .. ']]',
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
		pageName = record.pagename,
		standingsIndex = record.standingsindex,
		title = record.title,
		section = record.section,
		type = record.type,
		config = record.config,
		record = record,
		entryRecords = entries,
	}

	-- Some properties are derived from other properies and we can calculate them when accessed.
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
		positionChangeFromPreviousRound = tonumber(record.placementchange),
		record = record,
	}

	-- Some properties are derived from other properies and we can calculate them when accessed.
	setmetatable(entry, StandingsEntryMT)

	return entry
end

---@param standings StandingsModel
---@return MatchGroupUtilMatch[]
function Standings.fetchMatches(standings)
	---@diagnostic disable-next-line: invisible
	local matchids = standings.record.matches or {}
	local bracketIds = Array.unique(Array.map(matchids, function(matchid)
		return MatchGroupUtil.splitMatchId(matchid)
	end))

	local allMatchesFromBrackets = Array.flatMap(bracketIds, MatchGroupUtil.fetchMatches)
	return Array.filter(allMatchesFromBrackets, function(match)
		return Table.includes(matchids, match.matchId)
	end)
end

---@param entry StandingsEntryModel
---@return MatchGroupUtilMatch?
function Standings.fetchMatch(entry)
	---@diagnostic disable-next-line: invisible
	local matchid = entry.record.extradata.matchid
	if not matchid then
		return
	end
	local bracketId = MatchGroupUtil.splitMatchId(matchid)
	if not bracketId then
		return
	end

	local allMatchesFromBrackets = MatchGroupUtil.fetchMatches(bracketId)
	return Array.filter(allMatchesFromBrackets, function(match)
		return match.matchId == matchid
	end)[1]
end

---@param standings StandingsModel
---@return standingsentry[]
function Standings.fetchEntries(standings)
	local standingsEntries = {}
	local conditions = Condition.Tree(Condition.BooleanOperator.all)
		:add(Condition.Node(Condition.ColumnName('pagename'), Condition.Comparator.eq, standings.pageName))
		:add(Condition.Node(Condition.ColumnName('standingsindex'), Condition.Comparator.eq, standings.standingsIndex))

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
	---@diagnostic disable-next-line: invisible
	local record = standings.record
	---@diagnostic disable-next-line: invisible
	local standingsEntries = standings.entryRecords

	local roundCount = Array.maxBy(Array.map(standingsEntries, function(entry)
		return tonumber(entry.roundindex) or 1 end), FnUtil.identity)

	return Array.map(Array.range(1, roundCount or 1), function(roundIndex)
		local roundEntries = Array.filter(standingsEntries, function(entry)
			return tonumber(entry.roundindex) == roundIndex
		end)
		local opponents = Array.sortBy(Array.map(roundEntries, Standings.entryFromRecord), Operator.property('position'))
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
