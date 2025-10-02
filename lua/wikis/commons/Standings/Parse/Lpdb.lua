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

---@param rounds {roundNumber: integer, matches: string[]}[]
---@param scoreMapper fun(opponent: match2opponent): number|nil
---@return StandingTableOpponentData[]
function StandingsParseLpdb.importFromMatches(rounds, scoreMapper)
	local matchIds = Array.flatMap(rounds, function(round)
		return round.matches
	end)

	-- No Matches in the round, cannot import
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
				StandingsParseLpdb.parseMatch(roundNumber, match2, opponents, scoreMapper, #rounds)
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
		rounds = Array.map(Array.range(1, maxRounds), function()
			return {
				scoreboard = {
					match = {w = 0, d = 0, l = 0},
				},
			}
		end)
	}
end

---@param roundNumber integer
---@param match match2
---@param opponents StandingTableOpponentData[]
---@param scoreMapper fun(opponent: standardOpponent): number?
---@param maxRounds integer
function StandingsParseLpdb.parseMatch(roundNumber, match, opponents, scoreMapper, maxRounds)
	local match2 = MatchGroupUtil.matchFromRecord(match)
	Array.forEach(match2.opponents, function(opponent)
		---Find matching opponent
		local standingsOpponentData = Array.find(opponents, function(opponentData)
			return Opponent.same(opponentData.opponent, opponent)
		end)
		if not standingsOpponentData then
			standingsOpponentData = StandingsParseLpdb.newOpponent(opponent, maxRounds)
			table.insert(opponents, standingsOpponentData)
		end
		assert(standingsOpponentData.rounds[roundNumber], 'Round number out of bounds')

		local opponentRoundData = standingsOpponentData.rounds[roundNumber]
		opponentRoundData.specialstatus = ''
		opponentRoundData.match = match2
		if (not match2.finished) and (#match2.opponents <= 2) then
			return
		end
		local points = scoreMapper(opponent)
		if points then
			opponentRoundData.scoreboard.points = (opponentRoundData.scoreboard.points or 0) + points
		end
		local matchResult = match2.winner == 0 and 'd' or opponent.placement == 1 and 'w' or 'l'
		opponentRoundData.scoreboard.match[matchResult] = (opponentRoundData.scoreboard.match[matchResult] or 0) + 1
	end)
end

return StandingsParseLpdb
