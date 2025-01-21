---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Parse/Wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StandingsParseWiki = {}

--[[
{{FfaStandings|title=League Standings
|bg=1-10=stay, 11-20=down
|matches=...,...,...
<!-- Rounds -->
|round1={{Round|title=A vs B|started=true|finished=false}}
<more rounds>
<!-- Opponents -->
|opponent1={{TeamOpponent|dreamfire|placement=<optional>|r1=17|r2=-|r3=-|r4=34|r5=32|r6=-}}
<more opponents>
}}
]]

---@param args table
---@return table
function StandingsParseWiki.parseWikiInput(args)
	---@type {roundNumber: integer, started: boolean, finished:boolean, title: string?}[]
	local rounds = {}
	for _, roundData, roundIndex in Table.iter.pairsByPrefix(args, 'round', {requireIndex = true}) do
		table.insert(rounds, StandingsParseWiki.parseWikiRound(roundData, roundIndex))
	end

	---@type {rounds: {scoreboard: {points: number?}?}[]?, opponent: standardOpponent}[]
	local opponents = {}
	for _, opponentData, _ in Table.iter.pairsByPrefix(args, 'opponent', {requireIndex = true}) do
		table.insert(opponents, StandingsParseWiki.parseWikiOpponent(opponentData, #rounds))
	end

	return {
		rounds = rounds,
		opponents = opponents,
		bgs = StandingsParseWiki.parseWikiBgs(args.bg),
		matches = Array.parseCommaSeparatedString(args.matches),
	}
end

---@param roundInput string
---@param roundIndex integer
---@return {roundNumber: integer, started: boolean, finished:boolean, title: string?}[]
function StandingsParseWiki.parseWikiRound(roundInput, roundIndex)
	local roundData = Json.parse(roundInput)
	return {
		roundNumber = roundIndex,
		started = Logic.readBool(roundData.started),
		finished = Logic.readBool(roundData.finished),
		title = roundData.title,
	}
end

---@param opponentInput string
---@param numberOfRounds integer
---@return {rounds: {specialstatus: string, scoreboard: {points: number?}?}[]?, opponent: standardOpponent}[]
function StandingsParseWiki.parseWikiOpponent(opponentInput, numberOfRounds)
	local opponentData = Json.parse(opponentInput)
	local rounds = {}
	for i = 1, numberOfRounds do
		local input = opponentData['r' .. i]
		local points, specialStatus = nil, ''
		if Logic.isNumeric(input) then
			points = tonumber(input)
		else
			specialStatus = input
		end
		table.insert(rounds, {scoreboard = {points = points}, specialstatus = specialStatus})
	end
	return {rounds = rounds, opponent = Opponent.readOpponentArgs(opponentData)}
end

---@param input string
---@return table<integer, string>
function StandingsParseWiki.parseWikiBgs(input)
	local statusParsed = {}
	Array.forEach(Array.parseCommaSeparatedString(input, ','), function (status)
		local placements, color = unpack(Array.parseCommaSeparatedString(status, '='))
		local pStart, pEnd = unpack(Array.parseCommaSeparatedString(placements, '-'))
		local pStartNumber = tonumber(pStart) --[[@as integer]]
		local pEndNumber = tonumber(pEnd) or pStartNumber
		Array.forEach(Array.range(pStartNumber, pEndNumber), function(placement)
			statusParsed[placement] = color
		end)
	end)
	return statusParsed
end

return StandingsParseWiki
