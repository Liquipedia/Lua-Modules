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

---Adaptor for the tables of Module:GroupTableLeague/next/downstream and Module:SwissTableLeague/next
local StandingTableLegacyNext = {}

local MAX_ROUND_COUNT = 30
-- Bgs are set up to this slot, so the last one still applies if the opponents are undercounted
local MAX_SLOT_COUNT = 100
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

local ADJUSTMENTS = {
	temp_p = 'points',
	temp_tie = 'tiebreaker',
	temp_win_m = 'matchwins',
	temp_tie_m = 'matchdraws',
	temp_lose_m = 'matchlosses',
	temp_win_g = 'gamewins',
	temp_lose_g = 'gamelosses',
}

local MATCH_RESULTS = {matchwins = 'w', matchdraws = 'd', matchlosses = 'l'}

---Module:SwissTableLeague/next
---@param frame Frame
---@return Renderable
function StandingTableLegacyNext.run(frame)
	return StandingTableLegacyNext.build(Arguments.getArgs(frame), 'swiss')
end

---Module:GroupTableLeague/next/downstream
---@param frame Frame
---@return Renderable
function StandingTableLegacyNext.group(frame)
	return StandingTableLegacyNext.build(Arguments.getArgs(frame), 'group')
end

---@param args table
---@param tableType 'swiss'|'group'
---@return Renderable
function StandingTableLegacyNext.build(args, tableType)
	assert(args.tiebreaker1 ~= 'finalTiebreak', 'This SwissTableLeague has to be converted'
		.. ' manually due to using unsupported manual tiebreakers')

	local matchRecords = StandingTableLegacyNext.fetchMatches(args)
	local matchesByRound, roundCount = StandingTableLegacyNext.groupMatchesByRound(args, matchRecords)
	local rounds = Table.map(Array.range(1, roundCount), function(roundIndex)
		return 'round' .. roundIndex, StandingTableLegacySwiss.parseRoundInput(args, roundIndex, matchesByRound[roundIndex])
	end)

	local opponents = StandingTableLegacyNext.parseOpponents(args, roundCount)
	local opponentCount = StandingTableLegacyNext.countOpponents(
		opponents, matchRecords, StandingTableLegacyNext.readImportOpponents(args, opponents)
	)

	return StandingTable.fromTemplate(Table.merge(
		StandingTableLegacyNext.getStandardParameter(args, opponents, tableType),
		{bg = StandingTableLegacyNext.parseBgs(args, opponentCount)},
		rounds,
		opponents,
		{tiebreakers = StandingTableLegacyNext.parseTiebreakers(args)}
	))
end

---@param args table
---@param opponents table[]
---@param tableType 'swiss'|'group'|nil # Defaults to swiss
---@return table
function StandingTableLegacyNext.getStandardParameter(args, opponents, tableType)
	return Table.merge(StandingTableLegacySwiss.getStandardParameter(args), {
		tabletype = tableType or 'swiss',
		import = Logic.nilOr(Logic.readBoolOrNil(args.import), true),
		importopponents = StandingTableLegacyNext.readImportOpponents(args, opponents),
		store = Logic.readBoolOrNil(args.storeStanding),
		-- Legacy has no overtime, so `show_otp` is ignored
		overtime = false,
		points = StandingTableLegacySwiss.parsePoints(args, {
			resultDefaults = StandingTableLegacyNext.readResultPoints(args),
			overtime = false,
			decimalScores = true,
		}),
	})
end

---With any of `win_p`, `tie_p` and `lose_p` set, the unset ones are 0. Without them, a win is 3 points and
---a draw 1, unless `X-Y_p` is set, then the results are worth 0 and `X-Y_p` is all the points.
---@param args table
---@return {w: number, d: number, l: number}
function StandingTableLegacyNext.readResultPoints(args)
	local function read(key)
		local value = args[key]
		return value and assert(tonumber(value), 'Invalid ' .. key .. ': ' .. value) or nil
	end
	local hasResultPoints = args.win_p or args.tie_p or args.lose_p
	local hasScorePoints = Table.any(args, function(key)
		return tostring(key):match('^%d+%.?%d*%-%d+%.?%d*_p$') ~= nil
	end)
	local default = (hasResultPoints or hasScorePoints) and 0 or nil
	return {
		w = read('win_p') or default or 3,
		d = read('tie_p') or default or 1,
		l = read('lose_p') or 0,
	}
end

---@param args table
---@param opponents table[]
---@return boolean
function StandingTableLegacyNext.readImportOpponents(args, opponents)
	return Logic.nilOr(Logic.readBoolOrNil(args.importOpponents), #opponents == 0)
end

---Without imported opponents these are the listed ones,
---otherwise the unique non-TBD opponents of the matches are counted as well.
---@param opponents table[]
---@param matchRecords table[]
---@param importOpponents boolean
---@return integer
function StandingTableLegacyNext.countOpponents(opponents, matchRecords, importOpponents)
	if not importOpponents then
		return #opponents
	end
	local names = {}
	Array.forEach(matchRecords, function(matchRecord)
		Array.forEach(matchRecord.match2opponents or {}, function(opponentRecord)
			if not StandingTableLegacyNext.opponentRecordIsTbd(opponentRecord) then
				names[opponentRecord.name] = true
			end
		end)
	end)
	return math.max(#opponents, Table.size(names))
end

---@param opponentRecord table
---@return boolean
function StandingTableLegacyNext.opponentRecordIsTbd(opponentRecord)
	if opponentRecord.type == Opponent.team then
		return Logic.isEmpty(opponentRecord.name) or opponentRecord.name == 'TBD'
	elseif Opponent.typeIsParty(opponentRecord.type) then
		return Array.any(opponentRecord.match2players or {}, function(playerRecord)
			return Logic.isEmpty(playerRecord.displayname) or playerRecord.displayname == 'TBD'
		end)
	end
	return true
end

---A `pbg<N>` continues until the next one is set, with the first slot defaulting to `up`.
---Without any `pbg<N>`, the top quarter is `up`, the next quarter `stayup` and the bottom half `down`.
---@param args table
---@param opponentCount integer
---@return string
function StandingTableLegacyNext.parseBgs(args, opponentCount)
	local pbgs = {}
	for slotIndex = 1, MAX_SLOT_COUNT do
		pbgs[slotIndex] = args['pbg' .. slotIndex]
	end
	if Table.isEmpty(pbgs) then
		if opponentCount > 4 then
			pbgs[math.ceil(opponentCount / 4) + 1] = 'stayup'
		end
		if opponentCount > 1 then
			pbgs[math.ceil(opponentCount / 2) + 1] = 'down'
		end
	end

	local bg = 'up'
	local slotBgs = Array.map(Array.range(1, MAX_SLOT_COUNT), function(slotIndex)
		bg = pbgs[slotIndex] or bg
		return bg
	end)

	-- Consecutive slots with the same bg are written as a range
	local ranges = {}
	local rangeStart = 1
	for slotIndex, slotBg in ipairs(slotBgs) do
		if slotBgs[slotIndex + 1] ~= slotBg then
			local range = rangeStart == slotIndex and slotIndex or (rangeStart .. '-' .. slotIndex)
			table.insert(ranges, range .. '=' .. slotBg)
			rangeStart = slotIndex + 1
		end
	end
	return table.concat(ranges, ',')
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
		dq = StandingTableLegacyNext.parseDisqualifiedFromRound(args, index, roundCount),
		aliases = aliases and table.concat(Array.parseCommaSeparatedString(aliases), ';') or nil,
	},
		StandingTableLegacyNext.parseAdjustments(args, index, roundCount),
		StandingTableLegacyNext.parseDefiniteStatuses(args, index, roundCount)
	)
end

---Maps `round<R>temp_*<N>` to `r<R><adjustment>`. Unprefixed `temp_*<N>` adjust the final round, except
---`temp_tie<N>`, which applies from the first. Adjusted matches count towards the points, as in legacy.
---@param args table
---@param index integer
---@param roundCount integer
---@return table<string, number>
function StandingTableLegacyNext.parseAdjustments(args, index, roundCount)
	local resultPoints = StandingTableLegacyNext.readResultPoints(args)
	local adjustments = {}
	local function add(roundIndex, adjustment, value)
		local key = 'r' .. roundIndex .. adjustment
		adjustments[key] = (adjustments[key] or 0) + value
	end

	for input, adjustment in pairs(ADJUSTMENTS) do
		local keysByRound = Table.map(Array.range(1, roundCount), function(roundIndex)
			return roundIndex, {'round' .. roundIndex .. input .. index}
		end)
		table.insert(keysByRound[input == 'temp_tie' and 1 or roundCount], input .. index)

		for roundIndex, keys in pairs(keysByRound) do
			Array.forEach(keys, function(key)
				if args[key] == nil then
					return
				end
				local value = assert(tonumber(args[key]), 'Invalid ' .. key .. ': ' .. args[key])
				add(roundIndex, adjustment, value)
				local result = MATCH_RESULTS[adjustment]
				if result and resultPoints[result] ~= 0 then
					add(roundIndex, 'points', value * resultPoints[result])
				end
			end)
		end
	end
	return adjustments
end

---`round<R>dq<N>` disqualifies from round R, `dq<N>` from the final round.
---@param args table
---@param index integer
---@param roundCount integer
---@return integer?
function StandingTableLegacyNext.parseDisqualifiedFromRound(args, index, roundCount)
	return Array.find(Array.range(1, roundCount), function(roundIndex)
		return Logic.readBool(args['round' .. roundIndex .. 'dq' .. index])
			or (roundIndex == roundCount and Logic.readBool(args['dq' .. index]))
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
---@param matchRecords table[]
---@return table<integer, {id: string}[]>, integer
function StandingTableLegacyNext.groupMatchesByRound(args, matchRecords)
	local matches = Array.map(matchRecords, function(match)
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
		if roundIndex == 0 or roundIndex > roundCount then
			return roundCount
		end
		return roundIndex
	end)

	return matchesByRound, roundCount
end

---`rounds=<n>` sets the number of rounds and `rounds=false` (or `0`) disables reading it from the matches.
---Otherwise it is the highest round index of the matches.
---@param args table
---@param matches {round: integer?}[]
---@param inputRoundCount integer
---@return integer
function StandingTableLegacyNext.computeRoundCount(args, matches, inputRoundCount)
	local roundCount = tonumber(args.rounds)
	if roundCount and roundCount > 0 then
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
		query = 'match2id, date, match2bracketdata, match2opponents',
		order = 'date asc',
		limit = 1000,
	})
end

return StandingTableLegacyNext
