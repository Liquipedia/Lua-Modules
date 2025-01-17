---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Condition = require('Module:Condition')
local FnUtil = require('Module:FnUtil')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

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
---@field private lpdbdata standingstable

---@class StandingsRound
---@field round integer
---@field finished boolean
---@field title string
---@field opponents StandingsEntryModel[]

---@class StandingsEntryModel
---@field opponent standardOpponent
---@field placement string
---@field position integer
---@field points number
---@field positionStatus string?
---@field definitiveStatus string?
---@field positionChangeFromPreviousRound integer
---@field pointsChangeFromPreviousRound number

---@param pagename string
---@param standingsIndex integer #0-index'd on per page
---@return StandingsModel?
function Standings.getStandingsTable(pagename, standingsIndex)
	local pageNameInCorrectFormat = string.gsub(pagename, ' ', '_')
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
		end
		if property == 'matches' then
			standings[property] = Standings.fetchMatches(standings)
		end
		if property == 'rounds' then
			standings[property] = Standings.makeRounds(standings)
		end
		return rawget(standings, property)
	end
}

---@param record standingstable
---@return StandingsModel
function Standings.standingsFromRecord(record)
	local standings = {
		pageName = record.pagename,
		standingsIndex = record.standingsindex,
		title = record.title,
		section = record.section,
		type = record.type,
		config = record.config,
		rounds = record.rounds,
		lpdbdata = record,
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
		pointsChangeFromPreviousRound = record.extradata.pointschange,
		positionChangeFromPreviousRound = tonumber(record.placementchange),
	}

	return entry
end

---@param standings StandingsModel
---@return MatchGroupUtilMatch[]
function Standings.fetchMatches(standings)
	---@diagnostic disable-next-line: invisible
	local matchids = standings.lpdbdata.matches
	local bracketIds = Array.unique(Array.map(matchids, function(matchid)
		return MatchGroupUtil.splitMatchId(matchid)
	end))

	local allMatchesFromBrackets = Array.flatMap(bracketIds, MatchGroupUtil.fetchMatches)
	return Array.filter(allMatchesFromBrackets, function(match)
		return Table.includes(matchids, match.matchId)
	end)
end

---@param standings StandingsModel
---@return StandingsRound[]
function Standings.makeRounds(standings)
	---@diagnostic disable-next-line: invisible
	local lpdbdata = standings.lpdbdata
	local conditions = Condition.Tree(Condition.BooleanOperator.all)
		:add(Condition.Node(Condition.ColumnName('pagename'), Condition.Comparator.eq, standings.pageName))
		:add(Condition.Node(Condition.ColumnName('standingsindex'), Condition.Comparator.eq, standings.standingsIndex))

	local standingsEntries = {}
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

	local roundCount = Array.maxBy(Array.map(standingsEntries, Operator.property('roundindex')), FnUtil.identity)

	return Array.map(Array.range(1, roundCount), function(roundIndex)
		local roundEntries = Array.filter(standingsEntries, function(entry)
			return tonumber(entry.roundindex) == roundIndex
		end)
		local opponents = Array.sortBy(Array.map(roundEntries, Standings.entryFromRecord), Operator.property('position'))
		return {
			round = roundIndex,
			opponents = opponents,
			finished = (lpdbdata.extradata.rounds[roundIndex] or {}).finished,
			title = (lpdbdata.extradata.rounds[roundIndex] or {}).title,
		}
	end)
end

return Standings
