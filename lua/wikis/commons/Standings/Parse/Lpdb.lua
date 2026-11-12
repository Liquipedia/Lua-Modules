---
-- @Liquipedia
-- page=Module:Standings/Parse/Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Lpdb = Lua.import('Module:Lpdb')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local MathUtil = Lua.import('Module:MathUtil')
local Namespace = Lua.import('Module:Namespace')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local ConditionUtil = Condition.Util
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

local StandingsParseLpdb = {}

local MATCH_COLUMNS = {'match2id', 'match2opponents', 'bestof', 'date', 'dateexact', 'extradata', 'finished', 'winner'}

---@class StandingsImportOptions
---@field exclusive boolean? # If set, only matches where every opponent is part of the standings are imported
---@field importOpponents boolean? # If set, opponents not listed manually still count as part of the standings
---@field overtime boolean? # If set, results of overtime matches are tracked separately from regulation results
---@field includeGames boolean? # If set, the games of the matches are imported as well (always with overtime)
---@field dqHandling StandingsDqHandling? # How matches of disqualified opponents count from their dq round on

---@alias StandingsDqHandling 'ignore'|'autolose'

---@class StandingsDisqualificationContext
---@field dqHandling StandingsDqHandling
---@field scoreMapper fun(opponent: standardOpponent, match: MatchGroupUtilMatch): number|nil
---@field disqualifiedFromRound fun(opponent: standardOpponent): integer?
---@field forfeitedMatches table<string, MatchGroupUtilMatch> # Cache, keyed by match id and disqualified opponents

---@param rounds {roundNumber: integer, matches: string[]}[]
---@param scoreMapper fun(opponent: standardOpponent, match: MatchGroupUtilMatch): number|nil
---@param manualOpponents StandingTableOpponentData[]
---@param options StandingsImportOptions?
---@return StandingTableOpponentData[]
---@return table<integer, MatchPhase[]>
---@return number? maxBestOf # Includes matches between tbd opponents
function StandingsParseLpdb.importFromMatches(rounds, scoreMapper, manualOpponents, options)
	local matchIds = Array.flatMap(rounds, function(round)
		return round.matches
	end)

	-- No Matches, cannot import
	if #matchIds == 0 then
		return {}, {}
	end

	local matchIdToRound = {}
	Array.forEach(rounds, function(round)
		Array.forEach(round.matches, function(match)
			if matchIdToRound[match] then
				table.insert(matchIdToRound[match], round.roundNumber)
			else
				matchIdToRound[match] = {round.roundNumber}
			end
		end)
	end)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('namespace'), Comparator.neq, Namespace.matchNamespaceId()),
		StandingsParseLpdb.matchIdsCondition(matchIds),
	}

	---@type StandingTableOpponentData[]
	local opponents = {}
	---@type table<string, MatchPhase>
	local phaseByMatchId = {}
	---@type table<string, MatchGroupUtilMatch>
	local matchById = {}
	---@type number?
	local maxBestOf
	local lookupOpponent = StandingsParseLpdb.makeOpponentLookup(manualOpponents, options and options.importOpponents)
	local includeGames = options and (options.includeGames or options.overtime)
	Lpdb.executeMassQuery(
		'match2',
		{
			conditions = tostring(conditions),
			query = table.concat(Array.append(MATCH_COLUMNS, includeGames and 'match2games' or nil), ', '),
		},
		function(record)
			-- The match groups can hold matches that are not part of any round
			if not matchIdToRound[record.match2id] then
				return
			end
			record.match2games = record.match2games or {}
			local match2 = MatchGroupUtil.matchFromRecord(record)
			phaseByMatchId[record.match2id] = match2.phase
			matchById[record.match2id] = match2
			local mayBeRelevant = StandingsParseLpdb.parseMatch(
				matchIdToRound[record.match2id], match2, opponents, scoreMapper, #rounds, lookupOpponent, options
			)
			if mayBeRelevant then
				maxBestOf = MathUtil.nilSafeMax(maxBestOf, match2.bestof)
			end
		end
	)

	---@type StandingsDisqualificationContext?
	local disqualificationContext = options and options.dqHandling and {
		dqHandling = options.dqHandling,
		scoreMapper = scoreMapper,
		disqualifiedFromRound = StandingsParseLpdb.makeDisqualificationLookup(manualOpponents),
		forfeitedMatches = {},
	} or nil

	-- Matches that have been entered, but not created, are treated as upcoming
	local matchPhasesByRound = Table.map(rounds, function(_, round)
		return round.roundNumber, Array.map(round.matches, function(matchId)
			local match = matchById[matchId]
			if match and disqualificationContext
				and StandingsParseLpdb.hasDisqualifiedOpponent(match, round.roundNumber, disqualificationContext) then
				return 'finished'
			end
			return phaseByMatchId[matchId] or 'upcoming'
		end)
	end)

	local overtime = options and options.overtime
	local importedOpponents = Array.map(opponents, function(opponentData)
		if Opponent.isTbd(opponentData.opponent) then
			return
		end

		local matches = {}
		local previousTally

		return {
			opponent = opponentData.opponent,
			matchPoints = opponentData.matchPoints,
			rounds = Array.map(opponentData.rounds, function(roundData, roundNumber)
				local roundMatches = roundData.matches or {}
				matches = Array.extend(matches, roundMatches)
				local lastMatch = roundMatches[#roundMatches]
				local matchOpponentIndex = lastMatch
					and Array.indexOf(lastMatch.opponents, FnUtil.curry(Opponent.same, opponentData.opponent))
					or nil
				local round = {
					scoreboard = TiebreakerScope.tally(
						opponentData.opponent, roundMatches, opponentData.matchPoints, overtime
					),
					specialstatus = roundData.specialstatus or 'nc',
					matches = matches,
					matchId = lastMatch and lastMatch.matchId or nil,
					matchOpponentIndex = matchOpponentIndex,
				}
				if disqualificationContext then
					local changed
					round.matches, round.matchPoints, changed = StandingsParseLpdb.applyDisqualifications(
						opponentData.opponent, matches, opponentData.matchPoints, roundNumber, disqualificationContext
					)
					local tally = TiebreakerScope.tally(
						opponentData.opponent, round.matches, round.matchPoints, overtime
					)
					-- A disqualification also changes the earlier matches, so the round is the difference of the totals
					if changed then
						round.scoreboard = StandingsParseLpdb.subtractTally(tally, previousTally)
					end
					previousTally = tally
				end
				return round
			end)
		}
	end)

	return importedOpponents, matchPhasesByRound, maxBestOf
end

---Returns the round an opponent is disqualified from, read from the manual opponents.
---Opponents repeat across matches, so it is cached per distinct opponent.
---@param manualOpponents StandingTableOpponentData[]
---@return fun(opponent: standardOpponent): integer?
function StandingsParseLpdb.makeDisqualificationLookup(manualOpponents)
	local disqualifiedFromRoundByKey = {}
	return function(opponent)
		local key = StandingsParseLpdb.opponentKey(opponent)
		if disqualifiedFromRoundByKey[key] == nil then
			local manualOpponent = Array.find(manualOpponents, function(manualOpponent)
				return Opponent.same(manualOpponent.opponent, opponent)
			end)
			disqualifiedFromRoundByKey[key] = manualOpponent and manualOpponent.disqualifiedFromRound or false
		end
		return disqualifiedFromRoundByKey[key] or nil
	end
end

---Which opponents of a match are disqualified in a round
---@param match MatchGroupUtilMatch
---@param roundNumber integer
---@param context StandingsDisqualificationContext
---@return boolean[]
local function disqualifiedOpponents(match, roundNumber, context)
	return Array.map(match.opponents, function(opponent)
		local fromRound = context.disqualifiedFromRound(opponent)
		return fromRound ~= nil and fromRound <= roundNumber
	end)
end

---@param match MatchGroupUtilMatch
---@param roundNumber integer
---@param context StandingsDisqualificationContext
---@return boolean
function StandingsParseLpdb.hasDisqualifiedOpponent(match, roundNumber, context)
	return Array.any(disqualifiedOpponents(match, roundNumber, context), FnUtil.identity)
end

---The matches of an opponent as they count in a round. From the round an opponent is disqualified in, all its
---matches are left out (`ignore`) or lost by DQ (`autolose`), including the matches of earlier rounds.
---@param opponent standardOpponent
---@param matches MatchGroupUtilMatch[]
---@param matchPoints table<string, number>
---@param roundNumber integer
---@param context StandingsDisqualificationContext
---@return MatchGroupUtilMatch[] matches
---@return table<string, number> matchPoints
---@return boolean changed
function StandingsParseLpdb.applyDisqualifications(opponent, matches, matchPoints, roundNumber, context)
	local roundMatchPoints = matchPoints
	local changed = false
	local roundMatches = Array.map(matches, function(match)
		local disqualified = disqualifiedOpponents(match, roundNumber, context)
		if not Array.any(disqualified, FnUtil.identity) then
			return match
		end
		changed = true
		if context.dqHandling == 'ignore' then
			return nil
		end
		local forfeitedMatch = StandingsParseLpdb.forfeitMatch(match, disqualified, context.forfeitedMatches)
		if roundMatchPoints == matchPoints then
			roundMatchPoints = Table.copy(matchPoints)
		end
		local matchOpponent = Array.find(forfeitedMatch.opponents, FnUtil.curry(Opponent.same, opponent))
		---@cast matchOpponent -nil
		roundMatchPoints[match.matchId] = context.scoreMapper(matchOpponent, forfeitedMatch)
		return forfeitedMatch
	end)
	return roundMatches, roundMatchPoints, changed
end

---A finished copy of the match, won by walkover by the opponents that are not disqualified.
---Without such an opponent no one wins, the same as a match where every opponent is DQ.
---@param match MatchGroupUtilMatch
---@param disqualified boolean[]
---@param cache table<string, MatchGroupUtilMatch>
---@return MatchGroupUtilMatch
function StandingsParseLpdb.forfeitMatch(match, disqualified, cache)
	local key = match.matchId .. '|' .. table.concat(Array.map(disqualified, tostring), ',')
	if cache[key] then
		return cache[key]
	end
	local winner = Array.indexOf(disqualified, function(isDisqualified) return not isDisqualified end)
	cache[key] = Table.merge(match, {
		opponents = Array.map(match.opponents, function(opponent, index)
			return Table.merge(opponent, {
				status = disqualified[index] and 'DQ' or 'W',
				score = -1,
				placement = disqualified[index] and 2 or 1,
			})
		end),
		winner = winner > 0 and winner or -1,
		finished = true,
		phase = 'finished',
		resultType = 'default',
		walkover = 'dq',
		-- The played games no longer count
		games = {},
	})
	return cache[key]
end

---The difference between two tallies, without a previous tally it is the tally itself
---@param tally {points: number?, match: {w: integer, d: integer, l: integer}, overtime: {w: integer, l: integer}?}
---@param previous {points: number?, match: {w: integer, d: integer, l: integer}, overtime: {w: integer, l: integer}?}?
---@return {points: number?, match: {w: integer, d: integer, l: integer}, overtime: {w: integer, l: integer}?}
function StandingsParseLpdb.subtractTally(tally, previous)
	if not previous then
		return tally
	end
	local function subtract(record, previousRecord)
		return record and Table.map(record, function(key, value)
			return key, value - previousRecord[key]
		end) or nil
	end
	return {
		points = (tally.points or previous.points) and ((tally.points or 0) - (previous.points or 0)) or nil,
		match = subtract(tally.match, previous.match),
		overtime = subtract(tally.overtime, previous.overtime),
	}
end

---Builds the condition for fetching the matches. LPDB gets slow on a condition with many match ids
---(seconds for a few hundred), so the matches are fetched by their match group instead.
---@param matchIds string[]
---@return ConditionTree
function StandingsParseLpdb.matchIdsCondition(matchIds)
	local bracketIds = {}
	local unsplitMatchIds = {}
	Array.forEach(matchIds, function(matchId)
		local bracketId = MatchGroupUtil.splitMatchId(matchId)
		table.insert(bracketId and bracketIds or unsplitMatchIds, bracketId or matchId)
	end)
	-- Added one by one, as either is nil without values
	return ConditionTree(BooleanOperator.any)
		:add(ConditionUtil.anyOf(ColumnName('match2bracketid'), bracketIds))
		:add(ConditionUtil.anyOf(ColumnName('match2id'), unsplitMatchIds))
end

---@param opponentData standardOpponent
---@param maxRounds integer
---@return StandingTableOpponentData
function StandingsParseLpdb.newOpponent(opponentData, maxRounds)
	return {
		opponent = opponentData,
		matchPoints = {},
		rounds = Array.mapRange(1, maxRounds, function()
			return {}
		end)
	}
end

---@class StandingsImportOpponentLookup
---@field alias standardOpponent? # The manual opponent the opponent is an alias of
---@field isPartOfStandings boolean
---@field isTbd boolean
---@field opponentData StandingTableOpponentData? # Set once the opponent is part of a counted match

---Builds a cache key for an opponent, opponents with the same key are the same opponent.
---Ignores opponents that are only TBD by name, as valid opponents never are.
---Different keys can still be the same opponent (e.g. two templates sharing a historical template),
---those are matched by `Opponent.same` when the opponent is first looked up.
---@param opponent standardOpponent
---@return string
function StandingsParseLpdb.opponentKey(opponent)
	if opponent.type == Opponent.team then
		return opponent.type .. '|' .. (opponent.template or '')
	end
	return opponent.type .. '|' .. (Opponent.isTbd(opponent) and 'tbd|' or '') .. (Opponent.toName(opponent) or '')
end

---Returns a function that renames an opponent into the manual opponent it is an alias of, if any,
---and looks up how it relates to the standings.
---Opponents repeat across matches, so the lookup is cached per distinct opponent.
---@param manualOpponents StandingTableOpponentData[]
---@param importOpponents boolean?
---@return fun(opponent: standardOpponent): StandingsImportOpponentLookup
function StandingsParseLpdb.makeOpponentLookup(manualOpponents, importOpponents)
	---@type table<string, StandingsImportOpponentLookup>
	local lookupByKey = {}

	return function(opponent)
		-- The key has to be taken before the alias renames the opponent
		local key = StandingsParseLpdb.opponentKey(opponent)
		if not lookupByKey[key] then
			local alias = StandingsParseLpdb.findAlias(opponent, manualOpponents)
			lookupByKey[key] = {
				alias = alias,
				-- An alias is a manual opponent, so it is always part of the standings
				isPartOfStandings = alias ~= nil
					or StandingsParseLpdb.isPartOfStandings(opponent, manualOpponents, importOpponents),
				isTbd = Opponent.isTbd(opponent),
			}
		end

		local lookup = lookupByKey[key]
		if lookup.alias then
			opponent.template = lookup.alias.template
			opponent.name = lookup.alias.name
		end
		return lookup
	end
end

---Finds the manual opponent an opponent is an alias of, if any.
---Aliases are only supported for team opponents.
---@param opponent standardOpponent
---@param manualOpponents StandingTableOpponentData[]
---@return standardOpponent?
function StandingsParseLpdb.findAlias(opponent, manualOpponents)
	if opponent.type ~= Opponent.team then
		return
	end
	local opponentToUse = Array.find(manualOpponents, function(manualOpponent)
		return Array.any(manualOpponent.aliases or {}, function(alias)
			return Opponent.same(opponent, alias)
		end)
	end)
	return opponentToUse and opponentToUse.opponent or nil
end

---Checks whether an opponent ends up in the standings table, either because it is listed manually
---or because it gets imported from the matches.
---@param opponent standardOpponent
---@param manualOpponents StandingTableOpponentData[]
---@param importOpponents boolean?
---@return boolean
function StandingsParseLpdb.isPartOfStandings(opponent, manualOpponents, importOpponents)
	local isManualOpponent = Array.any(manualOpponents, function(manualOpponent)
		return Opponent.same(manualOpponent.opponent, opponent)
	end)
	if isManualOpponent then
		return true
	end
	if not importOpponents then
		return false
	end

	---Imported opponents are part of the standings too, but literal (and tbd) opponents are never imported
	return not Opponent.isTbd(opponent)
end

---@param roundNumbers integer[]
---@param match2 MatchGroupUtilMatch
---@param opponents StandingTableOpponentData[]
---@param scoreMapper fun(opponent: standardOpponent, match: MatchGroupUtilMatch): number?
---@param maxRounds integer
---@param lookupOpponent fun(opponent: standardOpponent): StandingsImportOpponentLookup
---@param options StandingsImportOptions?
---@return boolean mayBeRelevant # Whether the match counts, or may once its tbd opponents are known
function StandingsParseLpdb.parseMatch(roundNumbers, match2, opponents, scoreMapper, maxRounds, lookupOpponent, options)
	options = options or {}

	local lookups = Array.map(match2.opponents, lookupOpponent)

	--- In exclusive mode every opponent of the match has to be part of the standings,
	--- otherwise the match is not counted at all. In non-exclusive mode a single one is enough.
	local opponentCheck = options.exclusive and Array.all or Array.any
	local isRelevantMatch = opponentCheck(lookups, function(lookup)
		return lookup.isPartOfStandings
	end)
	if not isRelevantMatch then
		-- A tbd opponent may still turn out to be part of the standings
		return opponentCheck(lookups, function(lookup)
			return lookup.isPartOfStandings or lookup.isTbd
		end)
	end

	if options.overtime then
		-- A bestof of 0 means it was not set on the match
		assert(match2.bestof <= 1, 'Overtime standings only support Bo1 matches, but ' .. match2.matchId
			.. ' is a Bo' .. tostring(match2.bestof))
	end

	Array.forEach(match2.opponents, function(opponent, opponentIndex)
		local lookup = lookups[opponentIndex]
		lookup.opponentData = lookup.opponentData or Array.find(opponents, function(opponentData)
			return Opponent.same(opponentData.opponent, opponent)
		end)
		if not lookup.opponentData then
			lookup.opponentData = StandingsParseLpdb.newOpponent(opponent, maxRounds)
			table.insert(opponents, lookup.opponentData)
		end

		lookup.opponentData.matchPoints[match2.matchId] = scoreMapper(opponent, match2)
		Array.forEach(roundNumbers, function(roundNumber)
			-- The scoreboard of the round is tallied from these in importFromMatches
			local opponentRoundData = assert(lookup.opponentData.rounds[roundNumber], 'Round number out of bounds')
			opponentRoundData.specialstatus = ''
			opponentRoundData.matches = opponentRoundData.matches or {}
			table.insert(opponentRoundData.matches, match2)
		end)
	end)
	return true
end

return StandingsParseLpdb
