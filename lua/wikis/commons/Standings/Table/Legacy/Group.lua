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
	['series won'] = 'matchwins',
	['series loss'] = 'matchlosses',
	diff = 'gamediff',
	games = 'gamediff',
	['games won'] = 'gamewins',
	['games loss'] = 'gamelosses',
	['games percentage'] = 'gamewinrate',
	['games%'] = 'gamewinrate',
	['games-percentage'] = 'gamewinrate',
	['h2h series'] = 'h2hlegacy.matchscore',
	['head-to-head series'] = 'h2hlegacy.matchscore',
	['head to head series'] = 'h2hlegacy.matchscore',
	['h2h games'] = 'h2hlegacy.gamescore',
	['head-to-head games'] = 'h2hlegacy.gamescore',
	['head to head games'] = 'h2hlegacy.gamescore',
	['h2h diff'] = 'ml.rounddiff',
}

local DEFAULT_TIEBREAKERS = {'series', 'diff', 'h2h series', 'h2h games', 'games won', 'games loss'}

local ADJUSTMENTS = {
	temp_p = 'points',
	temp_tie = 'tiebreaker',
	temp_win_m = 'matchwins',
	temp_tie_m = 'matchdraws',
	temp_lose_m = 'matchlosses',
	temp_win_g = 'gamewins',
	temp_lose_g = 'gamelosses',
	temp_win_r = 'roundwins',
	temp_lose_r = 'roundlosses',
}

-- Legacy counts adjusted matches towards the points
local MATCH_RESULT_POINTS = {
	matchwins = {input = 'win_p', default = 3},
	matchdraws = {input = 'tie_p', default = 1},
	matchlosses = {input = 'lose_p', default = 0},
}

---@alias LegacyGroupRound {index: integer, endTime: integer?}
---@alias LegacyGroupOpponentParser fun(args: table, index: integer, rounds: LegacyGroupRound[]): table?

---Adjustments for the GroupTableLeague variants of wikis
---@class LegacyGroupConfig
---@field tiebreakers table<string, string>? # Overrides of the tiebreaker mapping
---@field defaultTiebreakers string[]? # Legacy tiebreaker names
---@field defaultPointsTiebreakers string[]? # Legacy tiebreaker names, with `show_p`

---Valorant has its own tiebreakers, `diff` is the round difference
---@type LegacyGroupConfig
StandingTableLegacyGroup.VALORANT_CONFIG = {
	tiebreakers = {
		diff = 'rounddiff',
		['diff games'] = 'gamediff',
		['rounds won'] = 'roundwins',
		['rounds loss'] = 'roundlosses',
		['h2h series'] = 'h2hcs.matchdiff',
		['head-to-head series'] = 'h2hcs.matchdiff',
		['head to head series'] = 'h2hcs.matchdiff',
		['h2h league'] = 'ml.matchdiff',
		['head-to-head league'] = 'ml.matchdiff',
		['head to head league'] = 'ml.matchdiff',
		['h2h rounds'] = 'h2hlegacy.rounddiff',
		['head-to-head rounds'] = 'h2hlegacy.rounddiff',
		['head to head rounds'] = 'h2hlegacy.rounddiff',
		['h2h rounds won'] = 'h2hlegacy.roundwins',
		['head-to-head rounds won'] = 'h2hlegacy.roundwins',
		['head to head rounds won'] = 'h2hlegacy.roundwins',
	},
	defaultTiebreakers = {
		'series', 'h2h series', 'h2h games', 'diff games', 'games won', 'h2h rounds', 'h2h rounds won', 'diff', 'rounds won',
	},
	defaultPointsTiebreakers = {'points'},
}

---Common local Module:GroupTableLeague
---@param frame Frame
---@return Renderable
function StandingTableLegacyGroup.classic(frame)
	return StandingTableLegacyGroup.run(Arguments.getArgs(frame))
end

---Module:GroupTableLeague of valorant
---@param frame Frame
---@return Renderable
function StandingTableLegacyGroup.valorant(frame)
	return StandingTableLegacyGroup.run(Arguments.getArgs(frame), StandingTableLegacyGroup.VALORANT_CONFIG)
end

---Module:GroupTableLeague/solo
---@param frame Frame
---@return Renderable
function StandingTableLegacyGroup.solo(frame)
	return StandingTableLegacyGroup.run(Arguments.getArgs(frame), nil, StandingTableLegacyGroup.parseSoloInput)
end

---@param args table
---@param config LegacyGroupConfig?
---@param parseOpponentInput LegacyGroupOpponentParser? # Defaults to team input
---@return Renderable
function StandingTableLegacyGroup.run(args, config, parseOpponentInput)
	parseOpponentInput = parseOpponentInput or StandingTableLegacyGroup.parseTeamInput
	local legacyRounds = StandingTableLegacyGroup.parseRounds(args, DateExt.getCurrentTimestamp())
	local matchesByRound = StandingTableLegacyGroup.groupMatchesByRound(
		legacyRounds, StandingTableLegacyNext.fetchMatches(args)
	)
	local rounds = Table.map(legacyRounds, function(roundNumber)
		local roundInput = StandingTableLegacyGroup.parseRoundInput(args, roundNumber, matchesByRound[roundNumber])
		return 'round' .. roundNumber, roundInput
	end)

	local opponents = Array.mapIndexes(function(index)
		return parseOpponentInput(args, index, legacyRounds)
	end)

	local tiebreakers = StandingTableLegacyGroup.parseTiebreakers(args, config)

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacyGroup.getStandardParameter(args, opponents),
		{bg = StandingTableLegacySwiss.parseWikiBgs(args, 'pbg')},
		rounds,
		opponents,
		{tiebreakers = tiebreakers, tiebreakerreset = StandingTableLegacyGroup.needsTiebreakerReset(tiebreakers)}
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
		walkoverrounds = StandingTableLegacyGroup.parseWalkoverRounds(args),
	})
end

---h2hcs only splits off the tops and bottoms, the reset applies it again to the opponents left tied
---@param tiebreakers string[]
---@return true?
function StandingTableLegacyGroup.needsTiebreakerReset(tiebreakers)
	return Array.any(tiebreakers, function(tiebreaker)
		return tiebreaker:match('^h2hcs%.') ~= nil
	end) or nil
end

---Legacy `walkover_rounds_win` counts for the whole match, the standings per map of the `walkover_win` maps
---@param args table
---@return integer?
function StandingTableLegacyGroup.parseWalkoverRounds(args)
	local rounds = tonumber(args.walkover_rounds_win)
	if not rounds then
		return nil
	end
	local maps = tonumber(args.walkover_win)
	return math.floor(rounds / ((maps and maps > 0) and maps or 1))
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
---@return {title: string, started: boolean, finished: boolean, matches: string}
function StandingTableLegacyGroup.parseRoundInput(args, roundNumber, matchIds)
	return {
		title = (args.roundtitle or 'Round') .. ' ' .. roundNumber,
		-- Legacy, so let's assume finished
		started = true,
		finished = true,
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

---The `dq`, `bg` and adjustment inputs of an opponent
---@param args table
---@param index integer
---@param rounds LegacyGroupRound[]
---@return table
local function parseOpponentRoundInputs(args, index, rounds)
	local dqInputs = readRoundInputs(args, 'dq', index, rounds)
	local disqualifiedRounds = Array.filter(Array.extractKeys(dqInputs), function(roundNumber)
		return Logic.readBool(dqInputs[roundNumber])
	end)

	return Table.merge(
		{dq = Array.min(disqualifiedRounds)},
		StandingTableLegacyGroup.parseAdjustments(args, index, rounds),
		Table.map(readRoundInputs(args, 'bg', index, rounds), function(roundNumber, status)
			return 'r' .. roundNumber .. 'bg', status
		end)
	)
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
	return Table.merge({
		type = Opponent.team,
		team,
		aliases = aliases and table.concat(Array.parseCommaSeparatedString(aliases), ';') or nil,
	}, parseOpponentRoundInputs(args, teamIndex, rounds))
end

---Legacy `player<N>` or `p<N>`, with `flag` and `link` suffixes
---@param args table
---@param playerIndex integer
---@param rounds LegacyGroupRound[]
---@return table?
function StandingTableLegacyGroup.parseSoloInput(args, playerIndex, rounds)
	local function read(suffix)
		return args['player' .. playerIndex .. suffix] or args['p' .. playerIndex .. suffix]
	end
	local player = read('')
	if not player then
		return nil
	end

	return Table.merge({
		type = Opponent.solo,
		player,
		flag = read('flag'),
		link = read('link'),
	}, parseOpponentRoundInputs(args, playerIndex, rounds))
end

---@param args table
---@param config LegacyGroupConfig?
---@return string[]
function StandingTableLegacyGroup.parseTiebreakers(args, config)
	config = config or {}
	local mapping = Table.merge(TIEBREAKER_MAPPING_TABLE, config.tiebreakers)
	local inputs = {}
	for _, value in Table.iter.pairsByPrefix(args, 'tiebreaker', {requireIndex = true}) do
		table.insert(inputs, value)
	end
	if #inputs == 0 and Logic.readBool(args.show_p) then
		inputs = config.defaultPointsTiebreakers or Array.extend('points', DEFAULT_TIEBREAKERS)
	elseif #inputs == 0 then
		inputs = config.defaultTiebreakers or DEFAULT_TIEBREAKERS
	end
	return Array.map(inputs, function(input)
		return assert(mapping[input], 'Unknown tiebreaker: ' .. input)
	end)
end

return StandingTableLegacyGroup
