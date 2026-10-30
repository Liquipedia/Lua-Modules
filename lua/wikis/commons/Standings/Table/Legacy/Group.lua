---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/Group
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local StandingTable = Lua.import('Module:Standings/Table')
local StandingTableLegacyNext = Lua.import('Module:Standings/Table/Legacy/Next')
local StandingTableLegacySwiss = Lua.import('Module:Standings/Table/Legacy/Swiss')

local Opponent = Lua.import('Module:Opponent/Custom')

---Adaptor for the group tables of the classic Module:GroupTableLeague
local StandingTableLegacyGroup = {}

-- Unprefixed inputs (`bg<N>`, `dq<N>`, ...) belong to the final round
local FINAL_ROUND_INDEX = 0

local TIEBREAKER_MAPPING_TABLE = {
	points = 'points',
	pts = 'points',
	series = 'matchscore',
	['series percentage'] = 'matchwinrate',
	['series%'] = 'matchwinrate',
	['series-percentage'] = 'matchwinrate',
	['series diff'] = 'matchdiff',
	diff = 'gamediff',
	['games won'] = 'gamewins',
	['games loss'] = 'gamelosses',
	['h2h series'] = 'h2hlegacy.matchscore',
	['head-to-head series'] = 'h2hlegacy.matchscore',
	['head to head series'] = 'h2hlegacy.matchscore',
	['h2h games'] = 'h2hlegacy.gamediff',
	['head-to-head games'] = 'h2hlegacy.gamediff',
	['head to head games'] = 'h2hlegacy.gamediff',
}

local DEFAULT_TIEBREAKERS = {
	'matchscore',
	'gamediff',
	'h2hlegacy.matchscore',
	'h2hlegacy.gamediff',
	'gamewins',
	'gamelosses',
}

local ADJUSTMENTS = {
	temp_p = 'points',
	temp_tie = 'tiebreaker',
	temp_win_m = 'matchwins',
	temp_tie_m = 'matchdraws',
	temp_lose_m = 'matchlosses',
	temp_win_g = 'gamewins',
	temp_lose_g = 'gamelosses',
}

-- Legacy counts adjusted matches towards the points
local MATCH_RESULT_POINTS = {
	matchwins = {input = 'win_p', default = 3},
	matchdraws = {input = 'tie_p', default = 1},
	matchlosses = {input = 'lose_p', default = 0},
}

---@alias LegacyGroupRound {index: integer, endTime: integer?}

---Common local Module:GroupTableLeague
---@param frame Frame
---@return Renderable
function StandingTableLegacyGroup.classic(frame)
	local args = Arguments.getArgs(frame)

	local legacyRounds = StandingTableLegacyGroup.parseRounds(args, os.time())
	local matchesByRound = StandingTableLegacyGroup.groupMatchesByRound(
		legacyRounds, StandingTableLegacyNext.fetchMatches(args)
	)
	local rounds = Table.map(legacyRounds, function(roundNumber)
		local roundInput = StandingTableLegacyGroup.parseRoundInput(args, roundNumber, matchesByRound[roundNumber])
		return 'round' .. roundNumber, roundInput
	end)

	local opponents = Array.mapIndexes(function(teamIndex)
		return StandingTableLegacyGroup.parseTeamInput(args, teamIndex, legacyRounds)
	end)

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacyGroup.getStandardParameter(args, opponents),
		{bg = StandingTableLegacySwiss.parseWikiBgs(args, 'pbg')},
		rounds,
		opponents,
		{tiebreakers = StandingTableLegacyGroup.parseTiebreakers(args)}
	))
end

---@param args table
---@param opponents table[]
---@return table
function StandingTableLegacyGroup.getStandardParameter(args, opponents)
	return Table.merge(StandingTableLegacySwiss.getStandardParameter(args), {
		tabletype = 'group',
		title = args.title or mw.title.getCurrentTitle().text,
		importopponents = #opponents == 0,
		width = args.width,
	})
end

---Reads `r<R><parameter><N>`, `round<R><parameter><N>` and `<parameter><N>`
---@param key string|integer
---@param parameter string
---@return integer? roundIndex, integer? index
local function readRoundKey(key, parameter)
	key = tostring(key)
	for _, prefix in ipairs{'r', 'round'} do
		local roundIndex, index = key:match('^' .. prefix .. '(%d+)' .. parameter .. '(%d*)$')
		if roundIndex then
			return tonumber(roundIndex), tonumber(index)
		end
	end
	local index = key:match('^' .. parameter .. '(%d*)$')
	if index then
		return FINAL_ROUND_INDEX, tonumber(index)
	end
end

---Rounds are ordered by their end date, followed by the final round unless a round is still to come
---@param args table
---@param now integer
---@return LegacyGroupRound[]
function StandingTableLegacyGroup.parseRounds(args, now)
	local edate = DateExt.readTimestampOrNil(args.edate)
	---@type table<integer, LegacyGroupRound>
	local roundsByIndex = {}
	for key, value in pairs(args) do
		local roundIndex = readRoundKey(key, 'date') or readRoundKey(key, 'edate')
		if roundIndex and roundIndex ~= FINAL_ROUND_INDEX then
			local endTime = DateExt.readTimestamp(value)
			if not edate or endTime <= edate then
				roundsByIndex[roundIndex] = {index = roundIndex, endTime = endTime}
			end
		end
	end
	local rounds = Array.sortBy(Array.extractValues(roundsByIndex), Operator.property('endTime'))

	local lastRound = rounds[#rounds]
	if not lastRound or (lastRound.endTime < (edate or now) and lastRound.endTime <= now) then
		table.insert(rounds, {index = FINAL_ROUND_INDEX, endTime = edate})
	end
	return rounds
end

---Assigns each match to the first round ending after it, or the last round
---@param rounds LegacyGroupRound[]
---@param matchRecords {match2id: string, date: string}[]
---@return table<integer, string[]>
function StandingTableLegacyGroup.groupMatchesByRound(rounds, matchRecords)
	local matchIdsByRound = {}
	Array.forEach(matchRecords, function(matchRecord)
		local time = DateExt.readTimestamp(matchRecord.date)
		local roundNumber = Array.indexOf(rounds, function(round)
			return not round.endTime or time <= round.endTime
		end)
		roundNumber = roundNumber == 0 and #rounds or roundNumber
		matchIdsByRound[roundNumber] = matchIdsByRound[roundNumber] or {}
		table.insert(matchIdsByRound[roundNumber], matchRecord.match2id)
	end)
	return matchIdsByRound
end

---@param args table
---@param roundNumber integer
---@param matchIds string[]?
---@return {title: string, matches: string}
function StandingTableLegacyGroup.parseRoundInput(args, roundNumber, matchIds)
	return {
		title = (args.roundtitle or 'Round') .. ' ' .. roundNumber,
		matches = table.concat(matchIds or {}, ','),
	}
end

---Keyed by the round number they apply from
---@param args table
---@param parameter string
---@param teamIndex integer
---@param rounds LegacyGroupRound[]
---@return table<integer, string>
local function readRoundInputs(args, parameter, teamIndex, rounds)
	local values = {}
	for key, value in pairs(args) do
		local roundIndex, index = readRoundKey(key, parameter)
		if index == teamIndex then
			local roundNumber = roundIndex == FINAL_ROUND_INDEX and #rounds or Array.indexOf(rounds, function(round)
				return round.index == roundIndex
			end)
			if roundNumber ~= 0 then
				values[roundNumber] = value
			end
		end
	end
	return values
end

---Maps the legacy `temp_*` inputs to `r<round><adjustment>`
---@param args table
---@param teamIndex integer
---@param rounds LegacyGroupRound[]
---@return table<string, number>
function StandingTableLegacyGroup.parseAdjustments(args, teamIndex, rounds)
	local adjustments = {}
	local function add(roundNumber, adjustment, value)
		local key = 'r' .. roundNumber .. adjustment
		adjustments[key] = (adjustments[key] or 0) + value
	end

	for parameter, adjustment in pairs(ADJUSTMENTS) do
		local resultPoints = MATCH_RESULT_POINTS[adjustment]
		local pointsPerMatch = resultPoints and (tonumber(args[resultPoints.input]) or resultPoints.default) or 0
		for roundNumber, input in pairs(readRoundInputs(args, parameter, teamIndex, rounds)) do
			local value = assert(tonumber(input), 'Invalid ' .. parameter .. teamIndex .. ': ' .. input)
			add(roundNumber, adjustment, value)
			if pointsPerMatch ~= 0 then
				add(roundNumber, 'points', value * pointsPerMatch)
			end
		end
	end
	return adjustments
end

---@param args table
---@param teamIndex integer
---@param rounds LegacyGroupRound[]
---@return table?
function StandingTableLegacyGroup.parseTeamInput(args, teamIndex, rounds)
	local team = args['team' .. teamIndex]
	if not team then
		return nil
	end

	local aliases = args['team' .. teamIndex .. 'alias']
	local dqInputs = readRoundInputs(args, 'dq', teamIndex, rounds)
	local disqualifiedRounds = Array.filter(Array.extractKeys(dqInputs), function(roundNumber)
		return Logic.readBool(dqInputs[roundNumber])
	end)

	return Table.merge({
		type = Opponent.team,
		team,
		dq = Array.min(disqualifiedRounds),
		aliases = aliases and table.concat(Array.parseCommaSeparatedString(aliases), ';') or nil,
	},
		StandingTableLegacyGroup.parseAdjustments(args, teamIndex, rounds),
		Table.map(readRoundInputs(args, 'bg', teamIndex, rounds), function(roundNumber, status)
			return 'r' .. roundNumber .. 'bg', status
		end)
	)
end

---@param args table
---@return string[]
function StandingTableLegacyGroup.parseTiebreakers(args)
	local tiebreakers = {}
	for _, value in Table.iter.pairsByPrefix(args, 'tiebreaker', {requireIndex = true}) do
		local mappedTiebreaker = TIEBREAKER_MAPPING_TABLE[value]
		assert(mappedTiebreaker, 'Unknown tiebreaker: ' .. value)
		table.insert(tiebreakers, mappedTiebreaker)
	end
	if #tiebreakers > 0 then
		return tiebreakers
	end
	return Array.extend(Logic.readBool(args.show_p) and 'points' or nil, DEFAULT_TIEBREAKERS)
end

return StandingTableLegacyGroup
