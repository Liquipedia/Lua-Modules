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

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local ConditionUtil = Condition.Util
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local StandingsParseLpdb = {}

---@class StandingsImportOptions
---@field exclusive boolean? # If set, only matches where every opponent is part of the standings are imported
---@field importOpponents boolean? # If set, opponents not listed manually are added to the standings

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

		return {
			opponent = opponentData.opponent,
			rounds = Array.map(opponentData.rounds, function(roundData)
				local match = roundData.match
				matches = Array.append(matches, match)
				return {
					scoreboard = {
						points = roundData.scoreboard.points,
						match = {
							w = roundData.scoreboard.match.w or 0,
							l = roundData.scoreboard.match.l or 0,
							d = roundData.scoreboard.match.d or 0,
						},
					},
					specialstatus = roundData.specialstatus or 'nc',
					matches = matches,
					matchId = match and match.matchId or nil,
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
			return {
				scoreboard = {
					match = {w = 0, d = 0, l = 0},
				},
			}
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

		local opponentRoundData = standingsOpponentData.rounds[roundNumber]
		local points = scoreMapper(opponent)
		if points then
			opponentRoundData.scoreboard.points = (opponentRoundData.scoreboard.points or 0) + points
		end
		opponentRoundData.specialstatus = ''
		opponentRoundData.match = match2
		if not match2.finished then
			return
		end
		local matchResult = match2.winner == 0 and 'd' or opponent.placement == 1 and 'w' or 'l'
		opponentRoundData.scoreboard.match[matchResult] = (opponentRoundData.scoreboard.match[matchResult] or 0) + 1
	end)
end

return StandingsParseLpdb
