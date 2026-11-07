---
-- @Liquipedia
-- page=Module:Standings/Parse/Wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ArgSchema = Lua.import('Module:ArgSchema')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
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
local StandingsParameters = Lua.import('Module:Standings/Parameters')
local TiebreakerFactory = Lua.import('Module:Standings/Tiebreaker/Factory')
local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

local StandingsParseWiki = {}

local DEFAULT_POINTS = StandingsParameters.DEFAULT_POINTS
local DEFAULT_OVERTIME_POINTS = StandingsParameters.DEFAULT_OVERTIME_POINTS
local RESULT_POINTS_KEYS = {win = 'w', draw = 'd', loss = 'l', otwin = 'otw', otloss = 'otl'}
local OVERTIME_POINTS_KEYS = {otw = true, otl = true}
local ADJUSTMENT_RECORDS = {
	match = {w = 'matchwins', d = 'matchdraws', l = 'matchlosses'},
	game = {w = 'gamewins', d = 'gamedraws', l = 'gamelosses'},
	round = {w = 'roundwins', l = 'roundlosses'},
}

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

---@param values table # The `StandingsParameters.header`
---@return {rounds: {roundNumber: integer, started: boolean?, finished: boolean?, title: string?, matches: string[]}[],
---opponents: StandingTableOpponentData[],
---bgs: table<integer, string>,
---matches: string[]}
function StandingsParseWiki.parseWikiInput(values)
	---@type {roundNumber: integer, started: boolean?, finished: boolean?, title: string?, matches: string[]}[]
	local rounds = Array.mapIndexes(function(roundIndex)
		local roundData = values['round{round}'][roundIndex]
		if not roundData then
			return nil
		end
		return StandingsParseWiki.parseWikiRound(ArgSchema.read(StandingsParameters.round, roundData), roundIndex)
	end)

	if Logic.isEmpty(rounds) then
		-- Without rounds, the header is the only round
		rounds = {StandingsParseWiki.parseWikiRound(values, 1)}
	end

	local date = values.date or DateExt.getContextualDateOrNow()

	---@type StandingTableOpponentData[]
	local opponents = Array.mapIndexes(function(opponentIndex)
		local opponentData = values['{opponent}'][opponentIndex]
		return opponentData and StandingsParseWiki.parseWikiOpponent(opponentData, #rounds, date) or nil
	end)

	local wrapperMatches = Array.extend(values.matches, Array.flatMap(rounds, function(round)
		return round.matches
	end))

	return {
		rounds = rounds,
		opponents = opponents,
		bgs = StandingsParseWiki.parseWikiBgs(values.bg),
		matches = Array.unique(wrapperMatches),
	}
end

---@param values table # The `StandingsParameters.round`, or the `StandingsParameters.header` without rounds
---@param roundIndex integer
---@return {roundNumber: integer, started: boolean?, finished: boolean?, title: string?, matches: string[]}
function StandingsParseWiki.parseWikiRound(values, roundIndex)
	local matches = values.matches
	local startDate = values.sdate or DateExt.defaultTimestamp
	local endDate = values.edate or DateExt.defaultTimestamp
	local matchGroupsSpec = {
		matchGroupIds = values.matchgroups,
		pageNames = {values.stages},
	}
	if Logic.isNotDeepEmpty(matchGroupsSpec) then
		local conditions = ConditionTree(BooleanOperator.all):add(TournamentStructure.getMatch2Filter(matchGroupsSpec))
		if not DateExt.isDefaultTimestamp(startDate) then
			conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, startDate))
		end
		if not DateExt.isDefaultTimestamp(endDate) then
			conditions:add(ConditionNode(ColumnName('date'), Comparator.le, endDate))
		end
		matches = Array.extend(matches, MatchGroupUtil.fetchMatchIds{
			conditions = conditions,
			limit = 1000,
		})
	end
	return {
		roundNumber = roundIndex,
		started = values.started,
		finished = values.finished,
		title = values.title,
		matches = Array.unique(matches),
	}
end

---@param opponentData table
---@param numberOfRounds integer
---@param resolveDate string|number?
---@return StandingTableOpponentData
function StandingsParseWiki.parseWikiOpponent(opponentData, numberOfRounds, resolveDate)
	local values = StandingsParseWiki.readOpponentValues(opponentData, numberOfRounds)
	local rounds = {}
	for i = 1, numberOfRounds do
		local input = values['r{round}'][i]
		local points, specialStatus = nil, ''
		if Logic.isNumeric(input) then
			points = tonumber(input)
		elseif input == '-' then
			specialStatus = 'nc'
		else
			specialStatus = input
		end
		table.insert(rounds, {
			scoreboard = {points = points},
			specialstatus = specialStatus,
		})
	end

	local opponent = Opponent.readOpponentArgs(opponentData)
	opponent = Opponent.resolve(opponent, resolveDate, {syncPlayer = true})

	local aliases
	if opponent.type == Opponent.team then
		aliases = {opponent}
		Array.extendWith(aliases,
			Array.map(values.aliases, function(alias)
				return Opponent.readOpponentArgs{type = Opponent.team, template = alias}
			end)
		)
	end

	return {
		rounds = rounds,
		opponent = opponent,
		aliases = aliases,
		startingPoints = values.startingpoints,
		disqualifiedFromRound = values.dq,
		definiteStatuses = StandingsParseWiki.parseDefiniteStatuses(values, numberOfRounds),
		minStatuses = StandingsParseWiki.parseMinStatuses(values, numberOfRounds),
		adjustments = StandingsParseWiki.parseAdjustments(values, numberOfRounds),
	}
end

---Reads the `StandingsParameters.opponent`, where inputs without a round apply to the final round.
---@param opponentData table
---@param numberOfRounds integer
---@return table
function StandingsParseWiki.readOpponentValues(opponentData, numberOfRounds)
	return ArgSchema.read(StandingsParameters.opponent, opponentData, {defaultIndex = numberOfRounds})
end

---@param byRound table<integer, string>
---@param numberOfRounds integer
---@return table<integer, string>?
local function upToRound(byRound, numberOfRounds)
	return Logic.nilIfEmpty(Table.filterByKey(byRound, function(round)
		return round <= numberOfRounds
	end))
end

---Manual statuses, keyed by the round they apply from.
---@param values table # The `StandingsParameters.opponent` of the opponent
---@param numberOfRounds integer
---@return table<integer, string>?
function StandingsParseWiki.parseDefiniteStatuses(values, numberOfRounds)
	return upToRound(values['r{round}status'], numberOfRounds)
end

---Manual minimum statuses, keyed by the round they apply from.
---@param values table # The `StandingsParameters.opponent` of the opponent
---@param numberOfRounds integer
---@return table<integer, string>?
function StandingsParseWiki.parseMinStatuses(values, numberOfRounds)
	return upToRound(values['r{round}minstatus'], numberOfRounds)
end

---Reads the manual adjustments of an opponent, keyed by the round they apply from.
---@param values table # The `StandingsParameters.opponent` of the opponent
---@param numberOfRounds integer
---@return table<integer, StandingsAdjustment>?
function StandingsParseWiki.parseAdjustments(values, numberOfRounds)
	local adjustments = {}
	for round = 1, numberOfRounds do
		local function read(input)
			return values['r{round}' .. input][round]
		end
		adjustments[round] = Logic.nilIfEmpty(Table.merge(
			{points = read('points'), tiebreaker = read('tiebreaker')},
			Table.mapValues(ADJUSTMENT_RECORDS, function(inputs)
				return Logic.nilIfEmpty(Table.mapValues(inputs, read))
			end)
		))
	end
	return Logic.nilIfEmpty(adjustments)
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

---Reads the `points` input of swiss and group standings, e.g. `win=3, draw=1, loss=0, 2-0=4`.
---`win`, `draw` and `loss` are the points of that result and are keyed `w`, `d` and `l`.
---With overtime, `otwin` and `otloss` are the points of an overtime result and are keyed `otw` and `otl`.
---`X-Y` is the fixed amount of points for an opponent scoring X against Y, replacing the points of its result.
---@param input string?
---@param overtime boolean?
---@param tableType 'swiss'|'group'|nil # Picks the default points, swiss if unset
---@return table<string, number>
function StandingsParseWiki.parsePoints(input, overtime, tableType)
	local points = Table.copy(overtime and DEFAULT_OVERTIME_POINTS or DEFAULT_POINTS[tableType or 'swiss'])
	local entries = Array.filter(Array.parseCommaSeparatedString(input), Logic.isNotEmpty)
	Array.forEach(entries, function(entry)
		local key, value = unpack(Array.parseCommaSeparatedString(entry, '='))
		local pointsKey = RESULT_POINTS_KEYS[key] or (key and key:match('^%d+%-%d+$') and key)
		assert(pointsKey, 'Invalid points input: unknown key "' .. tostring(key) .. '" in "' .. entry .. '"')
		assert(overtime or not OVERTIME_POINTS_KEYS[pointsKey],
			'Invalid points input: "' .. entry .. '" requires overtime to be enabled')
		points[pointsKey] = assert(tonumber(value), 'Invalid points input: "' .. entry .. '" is not a number')
	end)
	return points
end

local MAX_FORMAT_RESULTS = 10

---@type table<string, table>
local FORMAT_SHORTHANDS = {
	gsl = {'swiss', adv = 2},
	swiss = {'swiss'},
}

---@param value integer?
---@return boolean
local function isValidResultCount(value)
	return value ~= nil and value > 0 and value <= MAX_FORMAT_RESULTS
end

---@type table<string, fun(data: table, input: string): StandingsFormat>
local FORMAT_PARSERS = {
	swiss = function(data, input)
		local winsToAdvance = MathUtil.toInteger(data.adv)
		local lossesToEliminate = Logic.isEmpty(data.elim) and winsToAdvance or MathUtil.toInteger(data.elim)
		local bounds = 'an integer from 1 to ' .. MAX_FORMAT_RESULTS
		assert(isValidResultCount(winsToAdvance), 'Invalid format input: "' .. input .. '" needs adv as ' .. bounds)
		assert(isValidResultCount(lossesToEliminate), 'Invalid format input: "' .. input .. '" needs elim as ' .. bounds)
		---@cast winsToAdvance -nil
		---@cast lossesToEliminate -nil
		return {type = 'swiss', winsToAdvance = winsToAdvance, lossesToEliminate = lossesToEliminate}
	end,
}

---@param input string
---@return table?
local function parseFormatShorthand(input)
	local adv = input:match('^swiss(%d+)$')
	return FORMAT_SHORTHANDS[input] or (adv and {'swiss', adv = adv}) or nil
end

---Reads `format`: `gsl`, `swiss<N>` or `{{Json|swiss|adv=<N>|elim=<N>}}`, where `elim` defaults to `adv`.
---@param input string?
---@param tableType StandingsTableTypes
---@return StandingsFormat?
function StandingsParseWiki.parseFormat(input, tableType)
	if Logic.isEmpty(input) then
		return nil
	end
	---@cast input -nil
	local data = Json.parseIfTable(input) or parseFormatShorthand(input)
	assert(data, 'Invalid format input: unknown format "' .. input .. '"')
	assert(tableType ~= 'ffa', 'Invalid format input: ffa standings do not support a format')
	local formatType = data[1] or data['1']
	local parseFormatData = FORMAT_PARSERS[formatType]
	assert(parseFormatData, 'Invalid format input: unknown format type "' .. tostring(formatType) .. '"')
	return parseFormatData(data, input)
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
---@param values {points: string?, ['p{placement}']: table<integer, number>} # From `StandingsParameters.header`
---@param overtime boolean? # Overtime results get their own points, by default win 3, overtime win 2,
---overtime loss 1, loss 0
---@return fun(opponent: standardOpponent, match: MatchGroupUtilMatch): number|nil
function StandingsParseWiki.makeScoringFunction(tabletype, values, overtime)
	if tabletype == 'ffa' then
		local placementPoints = values['p{placement}']
		if not placementPoints[1] then
			return function(opponent)
				if opponent.status == 'S' then
					return tonumber(opponent.score)
				end
				return nil
			end
		end
		return function(opponent)
			return placementPoints[opponent.placement] or 0
		end
	elseif tabletype == 'swiss' or tabletype == 'group' then
		---@cast tabletype 'swiss'|'group'
		local points = StandingsParseWiki.parsePoints(values.points, overtime, tabletype)
		return function(opponent, match)
			if not match.finished then
				return nil
			end
			local result = TiebreakerScope.matchResult(match, opponent)
			-- Overtime takes priority over the score, as overtime is only supported for Bo1 matches,
			-- where the score of an overtime match does not differ from a regulation one
			if overtime and result ~= 'd' and StandingsOvertime.isOvertimeMatch(match) then
				return points['ot' .. result]
			end
			return points[getScoreKey(match, opponent)] or points[result]
		end
	end
	error('Unknown table type')
end

---@param input string[]?
---@param tableType StandingsTableTypes
---@return StandingsTiebreaker[]
function StandingsParseWiki.parseTiebreakers(input, tableType)
	local tiebreakers = Array.map(input or {}, TiebreakerFactory.validateAndNormalizeInput)
	if #tiebreakers == 0 then
		tiebreakers = {TiebreakerFactory.validateAndNormalizeInput(StandingsParameters.DEFAULT_TIEBREAKERS[tableType])}
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

---@param input string?
---@param opponents StandingTableOpponentData[]
---@return table?
function StandingsParseWiki.parsePlaceMapping(input, opponents)
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
