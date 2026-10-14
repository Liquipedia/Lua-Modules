---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/Next
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local StandingTable = Lua.import('Module:Standings/Table')
local StandingTableLegacySwiss = Lua.import('Module:Standings/Table/Legacy/Swiss')
local TiebreakerFactory = Lua.import('Module:Standings/Tiebreaker/Factory')
local TournamentStructure = Lua.import('Module:TournamentStructure')
local Condition = Lua.import('Module:Condition')

local Opponent = Lua.import('Module:Opponent/Custom')

---Adaptor for the swiss tables of Module:GroupTableLeague/next
local StandingTableLegacyNext = {}

local MAX_ROUND_COUNT = 30
local OPPONENT_PREFIXES = {'p', 't', 'team', 'opponent'}

local TIEBREAKER_MAPPING_TABLE = {
	pts = 'points',
	series = 'matchscore',
	diff = 'gamediff',
	['games won'] = 'gamewins',
	['games loss'] = 'gamelosses',
	['h2h series'] = 'ml.matchscore',
	['h2h games'] = 'ml.gamescore',
	['series diff'] = 'matchdiff',
	['series%'] = 'matchwinrate',
	['series percentage'] = 'matchwinrate',
	['series-percentage'] = 'matchwinrate',
	['game%'] = 'gamewinrate',
	['game percentage'] = 'gamewinrate',
	['game-percentage'] = 'gamewinrate',
}

-- These are always added by the standings, so they are dropped from the input
local IMPLICIT_TIEBREAKERS = {
	dq = true,
	finaltiebreak = true,
}

---Common local Module:GroupTableLeague
---@param frame Frame
---@return Renderable
function StandingTableLegacyNext.run(frame)
	local args = Arguments.getArgs(frame)

	local matchesByRound, roundCount = StandingTableLegacyNext.fetchMatchesByRound(args)
	local rounds = Table.map(Array.range(1, roundCount), function(roundIndex)
		return 'round' .. roundIndex, StandingTableLegacySwiss.parseRoundInput(args, roundIndex, matchesByRound[roundIndex])
	end)

	local opponents = StandingTableLegacyNext.parseOpponents(args, roundCount)

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacyNext.getStandardParameter(args, opponents),
		{bg = StandingTableLegacySwiss.parseWikiBgs(args, 'pbg')},
		rounds,
		opponents,
		{tiebreakers = StandingTableLegacyNext.parseTiebreakers(args)}
	))
end

---@param args table
---@param opponents table[]
---@return table
function StandingTableLegacyNext.getStandardParameter(args, opponents)
	return Table.merge(StandingTableLegacySwiss.getStandardParameter(args), {
		importopponents = Logic.nilOr(Logic.readBoolOrNil(args.importOpponents), #opponents == 0),
		store = Logic.readBoolOrNil(args.storeStanding),
	})
end

---Opponents are read from `p<N>` (solo), `t<N>`/`team<N>` (team), and `opponent<N>` or unprefixed
---arguments (opponent JSON, team name otherwise). Unprefixed arguments fill the gaps between prefixed ones.
---@param args table
---@param roundCount integer
---@return table[]
function StandingTableLegacyNext.parseOpponents(args, roundCount)
	return Table.mapArgumentsByPrefix(args, OPPONENT_PREFIXES, function(key, index, prefix)
		return StandingTableLegacyNext.parseOpponentInput(args, key, index, prefix, roundCount)
	end)
end

---@param args table
---@param key string|integer
---@param index integer
---@param prefix string?
---@param roundCount integer
---@return table
function StandingTableLegacyNext.parseOpponentInput(args, key, index, prefix, roundCount)
	local value = args[key]
	local opponent = Json.parseIfTable(value)
	if not opponent then
		if prefix == 'p' then
			opponent = {type = Opponent.solo, value, flag = args['p' .. index .. 'flag'], link = args['p' .. index .. 'link']}
		else
			opponent = {type = Opponent.team, value}
		end
	end

	local aliases = prefix and args[prefix .. index .. 'alias'] or args['alias' .. index]

	return Table.merge(opponent, {
		tiebreaker = args['temp_tie' .. index],
		startingpoints = args['temp_p' .. index],
		dq = StandingTableLegacyNext.parseDisqualifiedFromRound(args, index, roundCount),
		aliases = aliases and table.concat(Array.parseCommaSeparatedString(aliases), ';') or nil,
	}, StandingTableLegacyNext.parseDefiniteStatuses(args, index, roundCount))
end

---`dq<N>` disqualifies from the first round, `round<R>dq<N>` from round R.
---@param args table
---@param index integer
---@param roundCount integer
---@return integer?
function StandingTableLegacyNext.parseDisqualifiedFromRound(args, index, roundCount)
	if Logic.readBool(args['dq' .. index]) then
		return 1
	end
	return Array.find(Array.range(1, roundCount), function(roundIndex)
		return Logic.readBool(args['round' .. roundIndex .. 'dq' .. index])
	end)
end

---`round<R>bg<N>` maps to `r<R>bg` on the opponent, `bg<N>` applies to the final round.
---@param args table
---@param index integer
---@param roundCount integer
---@return table<string, string?>
function StandingTableLegacyNext.parseDefiniteStatuses(args, index, roundCount)
	return Table.map(Array.range(1, roundCount), function(roundIndex)
		---@type string?
		local status = args['round' .. roundIndex .. 'bg' .. index]
		if not status and roundIndex == roundCount then
			status = args['bg' .. index]
		end
		return 'r' .. roundIndex .. 'bg', status
	end)
end

---@param args table
---@return string[]
function StandingTableLegacyNext.parseTiebreakers(args)
	local tiebreakers = {}
	for _, value in Table.iter.pairsByPrefix(args, 'tiebreaker', {requireIndex = true}) do
		local tiebreaker = StandingTableLegacyNext.mapTiebreaker(value)
		if tiebreaker then
			table.insert(tiebreakers, tiebreaker)
		end
	end
	if #tiebreakers > 0 then
		return tiebreakers
	end
	return Array.extend(
		Logic.readBool(args.show_p) and 'points' or nil,
		'matchscore',
		'gamediff',
		'ml.matchdiff',
		'ml.gamescore',
		'gamewins',
		'gamelosses'
	)
end

---Maps an alias or a GroupTableLeague metric name (e.g. `matchWins`, `ml.gameScore`) to a tiebreaker
---@param input string
---@return string?
function StandingTableLegacyNext.mapTiebreaker(input)
	local lowered = input:lower()
	local tiebreaker = TIEBREAKER_MAPPING_TABLE[lowered] or lowered
	if IMPLICIT_TIEBREAKERS[tiebreaker] then
		return nil
	end
	-- Errors on unknown tiebreakers
	TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
	return tiebreaker
end

---Assigns the matches to rounds by their round index (set via `|round=` or the match section),
---falling back to the `round<R>edate` time windows for matches without one.
---@param args table
---@return table<integer, {id: string}[]>, integer
function StandingTableLegacyNext.fetchMatchesByRound(args)
	local matches = Array.map(StandingTableLegacyNext.fetchMatches(args), function(match)
		return {
			id = match.match2id,
			time = DateExt.readTimestamp(match.date),
			round = tonumber((match.match2bracketdata or {}).groupRoundIndex),
		}
	end)

	local roundEndTimes = Array.mapIndexes(function(roundIndex)
		return DateExt.readTimestamp(args['round' .. roundIndex .. 'edate'])
	end)

	local roundCount = StandingTableLegacyNext.computeRoundCount(args, matches, #roundEndTimes)

	local _, matchesByRound = Array.groupBy(matches, function(match)
		if match.round and match.round >= 1 and match.round <= roundCount then
			return match.round
		end
		local roundIndex = Array.indexOf(roundEndTimes, function(endTime)
			return match.time <= endTime
		end)
		return roundIndex ~= 0 and roundIndex or roundCount
	end)

	return matchesByRound, roundCount
end

---`rounds=<n>` sets the number of rounds and `rounds=false` disables reading it from the matches.
---Otherwise it is the highest round index of the matches.
---@param args table
---@param matches {round: integer?}[]
---@param inputRoundCount integer
---@return integer
function StandingTableLegacyNext.computeRoundCount(args, matches, inputRoundCount)
	local roundCount = tonumber(args.rounds)
	if roundCount then
		return roundCount
	end
	local importedRoundCount = 0
	if Logic.readBoolOrNil(args.rounds) ~= false then
		importedRoundCount = Array.max(Array.filter(Array.map(matches, Operator.property('round')), function(round)
			return round <= MAX_ROUND_COUNT
		end)) or 0
	end
	return math.max(inputRoundCount, importedRoundCount, 1)
end

---@param args table
---@return table[]
function StandingTableLegacyNext.fetchMatches(args)
	local tournamentStructureSpec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec()
	local conditions = Condition.Tree(Condition.BooleanOperator.all)
		:add(TournamentStructure.getMatch2Filter(tournamentStructureSpec))

	local sdate, edate = DateExt.readTimestampOrNil(args.sdate), DateExt.readTimestampOrNil(args.edate)
	if sdate then
		conditions:add(Condition.Node(Condition.ColumnName('date'), Condition.Comparator.ge, sdate))
	end
	if edate then
		conditions:add(Condition.Node(Condition.ColumnName('date'), Condition.Comparator.le, edate))
	end

	return mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(conditions),
		query = 'match2id, date, match2bracketdata',
		order = 'date asc',
		limit = 1000,
	})
end

return StandingTableLegacyNext
