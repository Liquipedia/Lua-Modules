---
-- @Liquipedia
-- page=Module:Standings/Parse/Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
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

---@class StandingsImportOptions
---@field exclusive boolean? # If set, only matches where every opponent is part of the standings are imported
---@field importOpponents boolean? # If set, opponents not listed manually still count as part of the standings

---@param rounds {roundNumber: integer, matches: string[]}[]
---@param scoreMapper fun(opponent: match2opponent): number|nil
---@param manualOpponents StandingTableOpponentData[]
---@param options StandingsImportOptions?
---@return StandingTableOpponentData[]
function StandingsParseLpdb.importFromMatches(rounds, scoreMapper, manualOpponents, options)
	local matchIds = Array.flatMap(rounds, function(round)
		return round.matches
	end)

	-- No Matches, cannot import
	if #matchIds == 0 then
		return {}
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
		ConditionUtil.anyOf(ColumnName('match2id'), matchIds),
	}

	---@type StandingTableOpponentData[]
	local opponents = {}
	Lpdb.executeMassQuery(
		'match2',
		{
			conditions = tostring(conditions),
		},
		function(match2)
			local roundNumbers = matchIdToRound[match2.match2id]
			Array.forEach(roundNumbers, function(roundNumber)
				StandingsParseLpdb.parseMatch(roundNumber, match2, opponents, scoreMapper, #rounds, manualOpponents, options)
			end)
		end
	)

	return Array.map(opponents, function(opponentData)
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
				return {
					scoreboard = TiebreakerScope.tally(opponentData.opponent, roundMatches, roundData.matchPoints),
					specialstatus = roundData.specialstatus or 'nc',
					matches = matches,
					matchPoints = matchPoints,
					matchId = lastMatch and lastMatch.matchId or nil,
				}
			end)
		}
	end)
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

---Renames an opponent into the manual opponent it is an alias of, if any.
---@param opponent standardOpponent
---@param manualOpponents StandingTableOpponentData[]
function StandingsParseLpdb.applyAliases(opponent, manualOpponents)
	local opponentToUse = Array.find(manualOpponents, function(manualOpponent)
		return Array.any(manualOpponent.aliases or {}, function(alias)
			return Opponent.same(opponent, alias)
		end)
	end)

	if not opponentToUse or not opponentToUse.opponent then
		return
	end

	opponent.template = opponentToUse.opponent.template
	opponent.name = opponentToUse.opponent.name
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

---@param roundNumber integer
---@param match match2
---@param opponents StandingTableOpponentData[]
---@param scoreMapper fun(opponent: standardOpponent): number?
---@param maxRounds integer
---@param manualOpponents StandingTableOpponentData[]
---@param options StandingsImportOptions?
function StandingsParseLpdb.parseMatch(roundNumber, match, opponents, scoreMapper, maxRounds, manualOpponents, options)
	options = options or {}
	local match2 = MatchGroupUtil.matchFromRecord(match)

	Array.forEach(match2.opponents, function(opponent)
		StandingsParseLpdb.applyAliases(opponent, manualOpponents)
	end)

	--- In exclusive mode every opponent of the match has to be part of the standings,
	--- otherwise the match is not counted at all. In non-exclusive mode a single one is enough.
	local opponentCheck = options.exclusive and Array.all or Array.any
	local isRelevantMatch = opponentCheck(match2.opponents, function(opponent)
		return StandingsParseLpdb.isPartOfStandings(opponent, manualOpponents, options.importOpponents)
	end)
	if not isRelevantMatch then
		return
	end

	Array.forEach(match2.opponents, function(opponent)
		local standingsOpponentData = Array.find(opponents, function(opponentData)
			return Opponent.same(opponentData.opponent, opponent)
		end)
		if not standingsOpponentData then
			standingsOpponentData = StandingsParseLpdb.newOpponent(opponent, maxRounds)
			table.insert(opponents, standingsOpponentData)
		end
		assert(standingsOpponentData.rounds[roundNumber], 'Round number out of bounds')

		-- The scoreboard of the round is tallied from these in importFromMatches
		local opponentRoundData = standingsOpponentData.rounds[roundNumber]
		opponentRoundData.specialstatus = ''
		opponentRoundData.matches = Array.append(opponentRoundData.matches or {}, match2)
		local points = scoreMapper(opponent)
		if points then
			opponentRoundData.matchPoints = opponentRoundData.matchPoints or {}
			opponentRoundData.matchPoints[match2.matchId] = points
		end
	end)
end

return StandingsParseLpdb
