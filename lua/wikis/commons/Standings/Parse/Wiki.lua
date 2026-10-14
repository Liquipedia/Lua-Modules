---
-- @Liquipedia
-- page=Module:Standings/Parse/Wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local StandingsOvertime = Lua.import('Module:Standings/Overtime')
local TiebreakerFactory = Lua.import('Module:Standings/Tiebreaker/Factory')
local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

local StandingsParseWiki = {}

local DEFAULT_SWISS_POINTS = {w = 1, d = 0.5, l = 0}
local RESULT_POINTS_KEYS = {win = 'w', draw = 'd', loss = 'l'}

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
---@return {roundNumber: integer, started: boolean, finished:boolean, title: string?, matches: string[]}
function StandingsParseWiki.parseWikiRound(roundInput, roundIndex)
	local roundData = Json.parseIfString(roundInput)
	local matches = Array.parseCommaSeparatedString(roundData.matches)
	local startDate = DateExt.readTimestamp(roundData.sdate) or DateExt.defaultTimestamp
	local endDate = DateExt.readTimestamp(roundData.edate) or DateExt.defaultTimestamp
	local matchGroupsSpec = {
		matchGroupIds = Array.parseCommaSeparatedString(roundData.matchgroups),
		pageNames = {Array.parseCommaSeparatedString(roundData.stages)},
	}
	if Logic.isNotDeepEmpty(matchGroupsSpec) then
		local conditions = ConditionTree(BooleanOperator.all):add(TournamentStructure.getMatch2Filter(matchGroupsSpec))
		if not DateExt.isDefaultTimestamp(startDate) then
			conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, startDate))
		end
		if not DateExt.isDefaultTimestamp(endDate) then
			conditions:add(ConditionNode(ColumnName('date'), Comparator.le, endDate))
		end
		Array.extendWith(matches, MatchGroupUtil.fetchMatchIds{
			conditions = conditions,
			limit = 1000,
		})
	end
	return {
		roundNumber = roundIndex,
		started = Logic.nilOr(
			Logic.readBoolOrNil(roundData.started),
			not DateExt.isDefaultTimestamp(startDate) and startDate <= DateExt.getCurrentTimestamp()
		),
		finished = Logic.nilOr(
			Logic.readBoolOrNil(roundData.finished),
			not DateExt.isDefaultTimestamp(endDate) and endDate <= DateExt.getCurrentTimestamp()
		),
		title = roundData.title,
		matches = Array.unique(matches),
	}
end

---@param opponentInput string|table
---@param numberOfRounds integer
---@param resolveDate string|number?
---@return StandingTableOpponentData
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

	local aliases
	if opponent.type == Opponent.team then
		aliases = {opponent}
		Array.extendWith(aliases,
			Array.map(Array.parseCommaSeparatedString(opponentData.aliases, ';'), function(alias)
				return Opponent.readOpponentArgs{type = Opponent.team, template = alias}
			end)
		)
	end

	return {
		rounds = rounds,
		opponent = opponent,
		aliases = aliases,
		startingPoints = opponentData.startingpoints,
		disqualifiedFromRound = StandingsParseWiki.parseDisqualifiedFromRound(opponentData.dq),
		definiteStatuses = StandingsParseWiki.parseDefiniteStatuses(opponentData, numberOfRounds),
	}
end

---Reads the `dq` input of an opponent. `dq=true` means disqualified from the first round,
---`dq=<number>` means disqualified from that round onwards.
---@param input string|number|boolean?
---@return integer?
function StandingsParseWiki.parseDisqualifiedFromRound(input)
	local fromRound = tonumber(input)
	if fromRound then
		return math.floor(fromRound)
	end
	return Logic.readBool(input) and 1 or nil
end

---Reads the `r<round>bg` inputs of an opponent, e.g. `r3bg=up`. The status applies from that round onwards.
---Rounds beyond the number of rounds and empty values are ignored.
---@param opponentData table
---@param numberOfRounds integer
---@return table<integer, string>?
function StandingsParseWiki.parseDefiniteStatuses(opponentData, numberOfRounds)
	local statuses = {}
	for round = 1, numberOfRounds do
		statuses[round] = Logic.nilIfEmpty(opponentData['r' .. round .. 'bg'])
	end
	return Logic.nilIfEmpty(statuses)
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

---Reads the `points` input of swiss standings, e.g. `win=3, draw=1, loss=0, 2-0=4`.
---`win`, `draw` and `loss` are the points of that result and are keyed `w`, `d` and `l`.
---`X-Y` is the fixed amount of points for an opponent scoring X against Y, replacing the points of its result.
---@param input string?
---@return table<string, number>
function StandingsParseWiki.parsePoints(input)
	local points = Table.copy(DEFAULT_SWISS_POINTS)
	local entries = Array.filter(Array.parseCommaSeparatedString(input), Logic.isNotEmpty)
	Array.forEach(entries, function(entry)
		local key, value = unpack(Array.parseCommaSeparatedString(entry, '='))
		local pointsKey = RESULT_POINTS_KEYS[key] or (key and key:match('^%d+%-%d+$') and key)
		assert(pointsKey, 'Invalid points input: unknown key "' .. tostring(key) .. '" in "' .. entry .. '"')
		points[pointsKey] = assert(tonumber(value), 'Invalid points input: "' .. entry .. '" is not a number')
	end)
	return points
end

---The score of the opponent in the format of the `X-Y` points input, nil if the match has no (proper) score.
---@param match MatchGroupUtilMatch
---@param opponent standardOpponent
---@return string?
local function getScoreKey(match, opponent)
	local opponents = match.opponents
	if #opponents ~= 2 then
		return nil
	end
	local hasScores = Array.all(opponents, function(matchOpponent)
		return matchOpponent.status == 'S' and Logic.isNumeric(matchOpponent.score)
	end)
	if not hasScores then
		return nil
	end
	local other = opponents[1] == opponent and opponents[2] or opponents[1]
	return opponent.score .. '-' .. other.score
end

---@param tabletype StandingsTableTypes
---@param args table
---@param overtime boolean? # Regulation win 3, overtime win 2, overtime loss 1, regulation loss 0
---@return fun(opponent: standardOpponent, match: MatchGroupUtilMatch): number|nil
function StandingsParseWiki.makeScoringFunction(tabletype, args, overtime)
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
		if overtime then
			return function(opponent, match)
				if not match.finished then
					return nil
				end
				-- Draws should not happen with overtime, but would be worth half a regulation win
				if match.winner == 0 then
					return 1.5
				end
				local isWinner = opponent.placement == 1
				if StandingsOvertime.isOvertimeMatch(match) then
					return isWinner and 2 or 1
				end
				return isWinner and 3 or 0
			end
		end
		local points = StandingsParseWiki.parsePoints(args.points)
		return function(opponent, match)
			if not match.finished then
				return nil
			end
			local scoreKey = getScoreKey(match, opponent)
			return points[scoreKey] or points[TiebreakerScope.matchResult(match, opponent)]
		end
	end
	error('Unknown table type')
end

---@param args table
---@param tableType StandingsTableTypes
---@return StandingsTiebreaker[]
function StandingsParseWiki.parseTiebreakers(args, tableType)
	local tiebreakerInput = Json.parseIfString(args.tiebreakers) or {}
	local tiebreakers = Array.map(tiebreakerInput, TiebreakerFactory.validateAndNormalizeInput)
	if #tiebreakers == 0 then
		if tableType == 'ffa' then
			tiebreakers = {
				TiebreakerFactory.validateAndNormalizeInput('points'),
			}
		elseif tableType == 'swiss' then
			tiebreakers = {
				TiebreakerFactory.validateAndNormalizeInput('matchdiff'),
			}
		end
	end
	if tableType == 'ffa' then
		Array.forEach(tiebreakers, function(tiebreaker)
			assert(
				TiebreakerFactory.parseId(tiebreaker) == 'full',
				'Tiebreaker "' .. tiebreaker .. '" is not supported, only full tiebreakers are supported in ffa standings'
			)
		end)
	end
	table.insert(tiebreakers, 1, TiebreakerFactory.validateAndNormalizeInput('disqualified'))
	table.insert(tiebreakers, TiebreakerFactory.validateAndNormalizeInput('manual'))
	return tiebreakers
end

---Reads which levels draws are explicitly enabled/disabled for. Unset (nil) means auto-detect from the data.
---@param args table
---@return {match: boolean?}
function StandingsParseWiki.parseDrawConfig(args)
	return {
		match = Logic.readBoolOrNil(args.matchdraws),
	}
end

---Reads whether overtime is tracked separately from regulation. Requires an overtime config on the wiki.
---@param args table
---@return boolean
function StandingsParseWiki.parseOvertime(args)
	local overtime = Logic.readBool(args.overtime)
	if overtime and not StandingsOvertime.regulationRounds() then
		error('Overtime standings require `Info.config.standings.overtime.regulationRounds` to be configured')
	end
	return overtime
end

---@param args table
---@param opponents StandingTableOpponentData[]
---@return table?
function StandingsParseWiki.parsePlaceMapping(args, opponents)
	local input = args.placements
	if not input then
		return
	end

	local function placementMappingError(msg)
		error('Invalid placement mapping: "' .. (input or 'nil') .. '" ' .. msg)
	end

	local mapping = {}
	Array.forEach(Array.parseCommaSeparatedString(input, ';'), function (place)
		local places = Array.parseCommaSeparatedString(place, '-')
		local startPlace = tonumber(places[1])
		local placeEnd = tonumber(places[#places])

		if (not startPlace) or (not placeEnd) or (placeEnd < startPlace) or #places > 2 then
			return placementMappingError('Invalid placement range: ' .. place)
		end

		Array.forEach(Array.range(startPlace, placeEnd), function(placeIndex)
			if mapping[placeIndex] then
				return placementMappingError('Duplicate placement mapping: ' .. placeIndex)
			end

			mapping[placeIndex] = startPlace
		end)
	end)

	local numberOfOpponents = #opponents

	if Table.size(mapping) > numberOfOpponents then
		placementMappingError('More placements than opponents: ' .. Table.size(mapping) .. ' > ' .. numberOfOpponents)
	end

	Array.forEach(Array.range(1, numberOfOpponents), function(placeIndex)
		if not mapping[placeIndex] then
			placementMappingError('Missing placement mapping for placement: ' .. placeIndex)
		end
	end)

	return mapping
end

return StandingsParseWiki
