---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local StandingsParseWiki = Lua.import('Module:Standings/Parse/Wiki')
local StandingsParseLpdb = Lua.import('Module:Standings/Parse/Lpdb')
local StandingsParser = Lua.import('Module:Standings/Parser')
local StandingsStorage = Lua.import('Module:Standings/Storage')

local Display = Lua.import('Module:Widget/Standings')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StandingsTable = {}

---@class Scoreboard
---@field points number?

---@class StandingTableOpponentData
---@field rounds {tiebreakerPoints: number?, specialstatus: string, scoreboard: Scoreboard?}[]?
---@field opponent standardOpponent
---@field startingPoints number?

---@class StandingsTableProps
---@field rounds {roundNumber: integer, started: boolean, finished:boolean, title: string?}[]
---@field opponents StandingTableOpponentData[]
---@field bgs table<integer, string>
---@field title string?
---@field endDate string #formated as YYYY-MM-DD
---@field matches string[]

---@param frame Frame
---@return Widget
function StandingsTable.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local tableType = args.tabletype
	if tableType ~= 'ffa' then
		error('Unknown Standing Table Type')
	end
	local importScoreFromMatches = Logic.nilOr(Logic.readBoolOrNil(args.import), true)
	local importOpponentFromMatches = Logic.nilOr(Logic.readBoolOrNil(args.importopponents), importScoreFromMatches)

	local parsedProps = StandingsParseWiki.parseWikiInput(args)

	if not importScoreFromMatches then
		return StandingsTable.ffa(parsedProps)
	end

	local rounds = parsedProps.rounds
	local opponents = parsedProps.opponents

	local importedOpponents = StandingsParseLpdb.importFromMatches(rounds, StandingsParseWiki.makeScoringFunction(args))
	parsedProps.opponents = StandingsTable.mergeOpponentsData(opponents, importedOpponents, importOpponentFromMatches)

	return StandingsTable.ffa(parsedProps)
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

---@param props StandingsTableProps
---@return Widget
function StandingsTable.ffa(props)
	local standingsTable = StandingsParser.parse(props)
	StandingsStorage.run(standingsTable)
	return Display{pageName = mw.title.getCurrentTitle().text, standingsIndex = standingsTable.standingsindex}
end

return StandingsTable
