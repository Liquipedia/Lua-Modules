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

	---@type {input: table, opponent: standardOpponent}[]
	local opponents = {}
	for _, opponentData, _ in Table.iter.pairsByPrefix(args, 'opponent', {requireIndex = true}) do
		table.insert(opponents, StandingsParseWiki.parseWikiOpponent(opponentData))
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
---@return table
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
---@return table
function StandingsParseWiki.parseWikiOpponent(opponentInput)
	local opponentData = Json.parse(opponentInput)
	return {input = opponentData, opponent = Opponent.readOpponentArgs(opponentData)}
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
