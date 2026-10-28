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

---@param rounds {roundNumber: integer, matches: string[]}[]
---@param scoreMapper fun(opponent: standardOpponent, match: MatchGroupUtilMatch): number|nil
---@param manualOpponents StandingTableOpponentData[]
---@param options StandingsImportOptions?
---@return StandingTableOpponentData[]
---@return table<integer, MatchPhase[]>
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
			local match2 = StandingsParseLpdb.slimMatch(MatchGroupUtil.matchFromRecord(record))
			phaseByMatchId[record.match2id] = match2.phase
			StandingsParseLpdb.parseMatch(
				matchIdToRound[record.match2id], match2, opponents, scoreMapper, #rounds, lookupOpponent, options
			)
		end
	)

	-- Matches that have been entered, but not created, are treated as upcoming
	local matchPhasesByRound = Table.map(rounds, function(_, round)
		return round.roundNumber, Array.map(round.matches, function(matchId)
			return phaseByMatchId[matchId] or 'upcoming'
		end)
	end)

	local importedOpponents = Array.map(opponents, function(opponentData)
		if Opponent.isTbd(opponentData.opponent) then
			return
		end

		local matches = {}
		local matchPoints = {}

		return {
			opponent = opponentData.opponent,
			rounds = Array.map(opponentData.rounds, function(roundData)
				local roundMatches = roundData.matches or {}
				matches = Array.extend(matches, roundMatches)
				matchPoints = Table.merge(matchPoints, roundData.matchPoints)
				local lastMatch = roundMatches[#roundMatches]
				local matchOpponentIndex = lastMatch
					and Array.indexOf(lastMatch.opponents, FnUtil.curry(Opponent.same, opponentData.opponent))
					or nil
				return {
					scoreboard = TiebreakerScope.tally(
						opponentData.opponent, roundMatches, roundData.matchPoints, options and options.overtime
					),
					specialstatus = roundData.specialstatus or 'nc',
					matches = matches,
					matchPoints = matchPoints,
					matchId = lastMatch and lastMatch.matchId or nil,
					matchOpponentIndex = matchOpponentIndex,
				}
			end)
		}
	end)

	return importedOpponents, matchPhasesByRound
end

---Keeps only what the standings read from a match, as the matches are held until the standings are stored.
---Teams are identified by their template, so their players are left out.
---@param match MatchGroupUtilMatch
---@return MatchGroupUtilMatch
function StandingsParseLpdb.slimMatch(match)
	return {
		matchId = match.matchId,
		finished = match.finished,
		winner = match.winner,
		bestof = match.bestof,
		phase = match.phase,
		opponents = Array.map(match.opponents, function(opponent)
			return {
				type = opponent.type,
				name = opponent.name,
				template = opponent.template,
				players = opponent.type == Opponent.team and {} or opponent.players,
				score = opponent.score,
				status = opponent.status,
				placement = opponent.placement,
			}
		end),
		games = Array.map(match.games, function(game)
			return {
				winner = game.winner,
				status = game.status,
				scores = game.scores,
				opponents = Array.map(game.opponents or {}, function(gameOpponent)
					return {status = gameOpponent.status}
				end),
			}
		end),
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
		rounds = Array.mapRange(1, maxRounds, function()
			return {}
		end)
	}
end

---@class StandingsImportOpponentLookup
---@field alias standardOpponent? # The manual opponent the opponent is an alias of
---@field isPartOfStandings boolean
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
		return
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

		local points = scoreMapper(opponent, match2)
		Array.forEach(roundNumbers, function(roundNumber)
			-- The scoreboard of the round is tallied from these in importFromMatches
			local opponentRoundData = assert(lookup.opponentData.rounds[roundNumber], 'Round number out of bounds')
			opponentRoundData.specialstatus = ''
			opponentRoundData.matches = opponentRoundData.matches or {}
			table.insert(opponentRoundData.matches, match2)
			if points then
				opponentRoundData.matchPoints = opponentRoundData.matchPoints or {}
				opponentRoundData.matchPoints[match2.matchId] = points
			end
		end)
	end)
end

return StandingsParseLpdb
