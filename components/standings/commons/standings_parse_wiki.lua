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
|opponent1={{TeamOpponent|dreamfire|r1=17|r2=-|r3=-|r4=34|r5=32|r6=-}}
<more opponents>
}}
]]

---@param args table
---@return {rounds: {roundNumber: integer, started: boolean, finished:boolean, title: string?, matches: string[]}[],
---opponents: StandingTableOpponentData[],
---bgs: table<integer, string>,
---matches: string[]}
function StandingsParseWiki.parseWikiInput(args)
	---@type {roundNumber: integer, started: boolean, finished:boolean, title: string?, matches: string[]}[]
	local rounds = {}
	for _, roundData, roundIndex in Table.iter.pairsByPrefix(args, 'round', {requireIndex = true}) do
		table.insert(rounds, StandingsParseWiki.parseWikiRound(roundData, roundIndex))
	end

	---@type StandingTableOpponentData[]
	local opponents = {}
	for _, opponentData, _ in Table.iter.pairsByPrefix(args, 'opponent', {requireIndex = true}) do
		table.insert(opponents, StandingsParseWiki.parseWikiOpponent(opponentData, #rounds))
	end

	local wrapperMatches = Array.parseCommaSeparatedString(args.matches)
	Array.extendWith(wrapperMatches, Array.flatMap(rounds, function(round)
		return round.matches
	end))

	return {
		rounds = rounds,
		opponents = opponents,
		bgs = StandingsParseWiki.parseWikiBgs(args.bg),
		matches = Array.unique(wrapperMatches),
	}
end

---@param roundInput string
---@param roundIndex integer
---@return {roundNumber: integer, started: boolean, finished:boolean, title: string?, matches: string[]}[]
function StandingsParseWiki.parseWikiRound(roundInput, roundIndex)
	local roundData = Json.parse(roundInput)
	local matches = Array.parseCommaSeparatedString(roundData.matches)
	local matchGroups = Array.parseCommaSeparatedString(roundData.matchgroups)
	if Logic.isNotEmpty(matchGroups) then
		matches = Array.extend(matches, Array.flatMap(matchGroups, function(matchGroupId)
			return StandingsParseWiki.getMatchIdsOfMatchGroup(matchGroupId)
		end))
	end
	return {
		roundNumber = roundIndex,
		started = Logic.readBool(roundData.started),
		finished = Logic.readBool(roundData.finished),
		title = roundData.title,
		matches = matches,
	}
end

---@param matchGroupId string
---@return string[]
function StandingsParseWiki.getMatchIdsOfMatchGroup(matchGroupId)
	local matchGroup = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = '[[match2bracketid::'.. matchGroupId ..']]',
		query = 'match2id',
		limit = '1000',
	})
	return Array.map(matchGroup, function(match)
		return match.match2id
	end)
end

---@param opponentInput string
---@param numberOfRounds integer
---@return StandingTableOpponentData[]
function StandingsParseWiki.parseWikiOpponent(opponentInput, numberOfRounds)
	local opponentData = Json.parse(opponentInput)
	local rounds = {}
	for i = 1, numberOfRounds do
		local input = opponentData['r' .. i]
		local points, specialStatus = nil, ''
		if Logic.isNumeric(input) then
			points = tonumber(input)
		elseif input == '-' then
			specialStatus = 'nc'
		else
			specialStatus = input
		end
		local tiebreakerPoints = numberOfRounds == i and tonumber(opponentData.tiebreaker) or nil
		table.insert(rounds, {scoreboard = {points = points}, specialstatus = specialStatus, tiebreakerPoints = tiebreakerPoints})
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

---@param args table
---@return (fun(opponent: match2opponent): number)|nil
function StandingsParseWiki.makeScoringFunction(args)
	if not args['p1'] then
		return nil
	end
	return function(opponent)
		local scoreFromPlacement = tonumber(args['p' .. opponent.placement])
		return scoreFromPlacement or 0
	end
end

return StandingsParseWiki
