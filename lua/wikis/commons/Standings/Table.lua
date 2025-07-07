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

local Display = Lua.import('Module:Widget/Standings')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StandingsTable = {}

---@alias StandingsTableTypes 'ffa'|'swiss'

---@class Scoreboard
---@field points number?
---@field match {w: integer, d: integer, l: integer}

---@class StandingTableOpponentData
---@field rounds {tiebreakerPoints: number?, specialstatus: string, scoreboard: Scoreboard?,
---match: MatchGroupUtilMatch?, matches: MatchGroupUtilMatch[], matchId: string}[]?
---@field opponent standardOpponent
---@field startingPoints number?

---@param frame Frame
---@return Widget
function StandingsTable.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local tableType = args.tabletype
	if tableType ~= 'ffa' and tableType ~= 'swiss' then
		error('Unknown Standing Table Type')
	end
	local title = args.title
	local importScoreFromMatches = Logic.nilOr(Logic.readBoolOrNil(args.import), true)
	local importOpponentFromMatches = Logic.nilOr(Logic.readBoolOrNil(args.importopponents), importScoreFromMatches)

	local parsedData = StandingsParseWiki.parseWikiInput(args)
	local rounds = parsedData.rounds
	local opponents = parsedData.opponents
	local bgs = parsedData.bgs
	local matches = parsedData.matches

	local tiebreakers = StandingsParseWiki.parseTiebreakers(args, tableType)

	if not importScoreFromMatches then
		return StandingsTable._make(rounds, opponents, bgs, title, matches, tableType, tiebreakers)
	end

	local automaticScoreFunction = StandingsParseWiki.makeScoringFunction(tableType, args)

	local importedOpponents = StandingsParseLpdb.importFromMatches(rounds, automaticScoreFunction)
	opponents = StandingsTable.mergeOpponentsData(opponents, importedOpponents, importOpponentFromMatches)
	return StandingsTable._make(rounds, opponents, bgs, title, matches, tableType, tiebreakers)
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
			return Opponent.toName(manualOpponent.opponent) == Opponent.toName(importedOpponent.opponent)
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

---@param rounds any
---@param opponents any
---@param bgs any
---@param title any
---@param matches any
---@param tableType StandingsTableTypes
---@param tiebreakers StandingsTiebreaker[]
---@return Widget
function StandingsTable._make(rounds, opponents, bgs, title, matches, tableType, tiebreakers)
	local standingsTable = StandingsParser.parse(rounds, opponents, bgs, title, matches, tableType, tiebreakers)
	StandingsStorage.run(standingsTable, {saveVars = true})
	return Display{pageName = mw.title.getCurrentTitle().text, standingsIndex = standingsTable.standingsindex}
end

return StandingsTable
