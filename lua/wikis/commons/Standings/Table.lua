---
-- @Liquipedia
-- page=Module:Standings/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local StandingsParseWiki = Lua.import('Module:Standings/Parse/Wiki')
local StandingsParseLpdb = Lua.import('Module:Standings/Parse/Lpdb')
local StandingsParser = Lua.import('Module:Standings/Parser')
local StandingsStorage = Lua.import('Module:Standings/Storage')

local Standings = Lua.import('Module:Standings')
local StandingsDisplay = Lua.import('Module:Widget/Standings')

local Opponent = Lua.import('Module:Opponent/Custom')

local StandingsTable = {}

---@alias StandingsTableTypes 'ffa'|'swiss'|'group'

local TABLE_TYPES = {ffa = true, swiss = true, group = true}

---@class Scoreboard
---@field points number?
---@field match {w: integer, d: integer, l: integer}
---@field overtime {w: integer, l: integer}?

---@class StandingsAdjustment
---@field points number?
---@field tiebreaker number?
---@field match {w: integer?, d: integer?, l: integer?}?
---@field game {w: integer?, d: integer?, l: integer?}?
---@field round {w: integer?, l: integer?}?

---@class StandingTableOpponentData
---@field rounds {specialstatus: string, scoreboard: Scoreboard?,
---matches: MatchGroupUtilMatch[], matchId: string, matchOpponentIndex: integer?}[]?
---@field opponent standardOpponent
---@field matchPoints table<string, number>? # The points of each imported match, keyed by match id
---@field aliases standardOpponent[]? # Only for team opponents
---@field startingPoints number?
---@field disqualifiedFromRound integer? # The first round in which the opponent is disqualified
---@field definiteStatuses table<integer, string>? # Manually set definite statuses, keyed by the round they apply from
---@field adjustments table<integer, StandingsAdjustment>? # Keyed by the round they apply from

---@param frame Frame
---@return Renderable
function StandingsTable.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local tableType = args.tabletype
	if not TABLE_TYPES[tableType] then
		error('Unknown Standing Table Type')
	end
	local storeLpdb = Logic.nilOr(Logic.readBoolOrNil(args.store), true)

	-- Parsed separately so the imported matches are released before storage
	local standingsTable = StandingsTable.parse(args, tableType)

	local record, entries = StandingsStorage.run(standingsTable, {storeLpdb = storeLpdb})
	---@cast record -nil
	return StandingsDisplay{
		standings = Standings.standingsFromRecord(record, entries),
		width = StandingsParseWiki.parseWidth(args),
	}
end

---@param args table
---@param tableType StandingsTableTypes
---@return StandingsTableStorage
function StandingsTable.parse(args, tableType)
	local title = args.title
	local importScoreFromMatches = Logic.nilOr(Logic.readBoolOrNil(args.import), true)
	local importOpponentFromMatches = Logic.nilOr(Logic.readBoolOrNil(args.importopponents), importScoreFromMatches)
	--- Exclusive standings only count matches where all opponents are part of the standings,
	--- non-exclusive (the default) counts matches where at least one opponent is part of the standings.
	--- Note that this is the reverse of the legacy GroupTableLeague default, on purpose.
	local exclusiveOpponents = Logic.readBool(args.exclusive)
	--- With tiebreaker reset, opponents split by a tiebreaker are compared again starting from the first tiebreaker.
	local tiebreakerReset = Logic.readBool(args.tiebreakerreset)

	local parsedData = StandingsParseWiki.parseWikiInput(args)
	local rounds = parsedData.rounds
	local opponents = parsedData.opponents
	local bgs = parsedData.bgs
	local matches = parsedData.matches

	local tiebreakers = StandingsParseWiki.parseTiebreakers(args, tableType)
	local overtime = StandingsParseWiki.parseOvertime(args)

	---@type table<integer, MatchPhase[]>
	local matchPhasesByRound = {}
	if importScoreFromMatches then
		local automaticScoreFunction = StandingsParseWiki.makeScoringFunction(tableType, args, overtime)

		local importedOpponents
		importedOpponents, matchPhasesByRound = StandingsParseLpdb.importFromMatches(
			rounds, automaticScoreFunction, opponents, {
				exclusive = exclusiveOpponents,
				importOpponents = importOpponentFromMatches,
				overtime = overtime,
				includeGames = StandingsParser.needsGames(tableType, tiebreakers),
			}
		)
		opponents = StandingsTable.mergeOpponentsData(opponents, importedOpponents, importOpponentFromMatches)
	end

	Array.forEach(rounds, function(round)
		round.started, round.finished = StandingsParser.resolveRoundStatus(round, matchPhasesByRound[round.roundNumber])
	end)

	local standingsTable = StandingsParser.parse(rounds, opponents, bgs, title, matches, tableType, tiebreakers, {
		drawConfig = StandingsParseWiki.parseDrawConfig(args),
		overtime = overtime,
		walkoverGames = StandingsParseWiki.parseWalkoverGames(args),
		walkoverRounds = StandingsParseWiki.parseWalkoverRounds(args),
		tiebreakerReset = tiebreakerReset,
	})

	if tableType == 'swiss' then
		standingsTable.extradata.placemapping = Logic.wrapTryOrLog(StandingsParseWiki.parsePlaceMapping)(args, opponents)
	end

	return standingsTable
end

---@param manualOpponents StandingTableOpponentData[]
---@param importedOpponents StandingTableOpponentData[]
---@param addNewOpponents boolean
---@return StandingTableOpponentData[]
function StandingsTable.mergeOpponentsData(manualOpponents, importedOpponents, addNewOpponents)
	--- Add all manual opponents to the new opponents list
	local newOpponents = Array.map(manualOpponents, FnUtil.identity)

	--- Find all imported opponents
	Array.forEach(importedOpponents, function(importedOpponent)
		--- Find the matching manual opponent
		local manualOpponentId = Array.indexOf(newOpponents, function(manualOpponent)
			return Opponent.same(manualOpponent.opponent, importedOpponent.opponent)
		end)
		--- If there isn't one, means this is a new opponent
		if manualOpponentId == 0 then
			if addNewOpponents then
				table.insert(newOpponents, importedOpponent)
			end
			return
		end
		--- Manual data has priority over imported data
		newOpponents[manualOpponentId] = Table.deepMerge(importedOpponent, newOpponents[manualOpponentId])
	end)

	return newOpponents
end

return StandingsTable
