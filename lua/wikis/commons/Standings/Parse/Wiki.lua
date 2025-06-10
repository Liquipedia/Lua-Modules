---
-- @Liquipedia
-- page=Module:Standings/Parse/Wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local TiebreakerFactory = Lua.import('Module:Standings/Tiebreaker/Factory')

local StandingsParseWiki = {}

--[[
{{FfaStandings|title=League Standings
|bg=1-10=stay, 11-20=down
|matches=...,...,...
<!-- Rounds -->
|round1={{Round|title=A vs B|started=true|finished=false}}
<more rounds>
<!-- Opponents -->
|{{TeamOpponent|dreamfire|r1=17|r2=-|r3=-|r4=34|r5=32|r6=-}}
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

	if Logic.isEmpty(rounds) then
		rounds = {StandingsParseWiki.parseWikiRound(args, 1)}
	end

	local date = DateExt.readTimestamp(args.date) or DateExt.getContextualDateOrNow()

	---@type StandingTableOpponentData[]
	local opponents = Array.map(args, function (opponentData)
		return StandingsParseWiki.parseWikiOpponent(opponentData, #rounds, date)
	end)

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

---@param roundInput string|table
---@param roundIndex integer
---@return {roundNumber: integer, started: boolean, finished:boolean, title: string?, matches: string[]}[]
function StandingsParseWiki.parseWikiRound(roundInput, roundIndex)
	local roundData = Json.parseIfString(roundInput)
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

---@param opponentInput string|table
---@param numberOfRounds integer
---@param resolveDate string|number?
---@return StandingTableOpponentData[]
function StandingsParseWiki.parseWikiOpponent(opponentInput, numberOfRounds, resolveDate)
	local opponentData = Json.parseIfString(opponentInput)
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
		table.insert(rounds, {
			scoreboard = {points = points},
			specialstatus = specialStatus,
			tiebreakerPoints = tiebreakerPoints,
		})
	end

	local opponent = Opponent.readOpponentArgs(opponentData)
	opponent = Opponent.resolve(opponent, resolveDate, {syncPlayer = true})

	return {
		rounds = rounds,
		opponent = opponent,
		startingPoints = opponentData.startingpoints,
	}
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

---@param tabletype StandingsTableTypes
---@param args table
---@return fun(opponent: match2opponent): number|nil
function StandingsParseWiki.makeScoringFunction(tabletype, args)
	if tabletype == 'ffa' then
		if not args['p1'] then
			return function(opponent)
				if opponent.status == 'S' then
					return tonumber(opponent.score)
				end
				return nil
			end
		end
		return function(opponent)
			local scoreFromPlacement = tonumber(args['p' .. opponent.placement])
			return scoreFromPlacement or 0
		end
	elseif tabletype == 'swiss' then
		return function(opponent)
			return opponent.placement == 1 and 1 or 0
		end
	end
	error('Unknown table type')
end

---@param args table
---@param tableType StandingsTableTypes
---@return StandingsTiebreaker[]
function StandingsParseWiki.parseTiebreakers(args, tableType)
	local tiebreakerInput = Json.parseIfString(args.tiebreakers) or {}
	local tiebreakers = {}
	for _, tiebreaker in ipairs(tiebreakerInput) do
		table.insert(tiebreakers, TiebreakerFactory.tiebreakerFromName(tiebreaker))
	end
	if #tiebreakers == 0 then
		if tableType == 'ffa' then
			tiebreakers = {
				TiebreakerFactory.tiebreakerFromName('points'),
				TiebreakerFactory.tiebreakerFromName('manual'),
			}
		elseif tableType == 'swiss' then
			tiebreakers = {
				TiebreakerFactory.tiebreakerFromName('matchdiff'),
				TiebreakerFactory.tiebreakerFromName('manual'),
			}
		end
	end
	return tiebreakers
end

return StandingsParseWiki
