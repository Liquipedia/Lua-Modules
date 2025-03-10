---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Parse/Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Condition = require('Module:Condition')
local Lpdb = require('Module:Lpdb')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

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

	local conditionsMatches = Condition.Tree(Condition.BooleanOperator.any)
	Array.forEach(matchIds, function(matchId)
		conditionsMatches:add(Condition.Node(Condition.ColumnName('match2id'), Condition.Comparator.eq, matchId))
	end)

	local opponents = {}
	Lpdb.executeMassQuery(
		'match2',
		{
			conditions = conditionsMatches:toString(),
			query = 'match2opponents',
		},
		function(match2)
			local roundNumbers = matchIdToRound[match2.match2id]
			Array.forEach(roundNumbers, function(roundNumber)
				StandingsParseLpdb.parseMatch(roundNumber, match2, opponents, scoreMapper, #rounds)
			end)
		end
	)

	return Array.map(opponents, function(opponentData)
		local opponent = Opponent.fromMatch2Record(opponentData.opponent)

		if Opponent.isTbd(opponent) then
			return
		end

		return {
			opponent = opponent,
			rounds = Array.map(opponentData.rounds, function(roundData)
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
					matchId = roundData.matchId
				}
			end)
		}
	end)
end

---@param opponentData match2opponent
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
---@param scoreMapper fun(opponent: match2opponent): number?
---@param maxRounds integer
function StandingsParseLpdb.parseMatch(roundNumber, match, opponents, scoreMapper, maxRounds)
	Array.forEach(match.match2opponents, function(opponent)
		---Find matching opponent
		local standingsOpponentData = Array.find(opponents, function(opponentData)
			return opponentData.opponent.name == opponent.name
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
		opponentRoundData.matchId = match.match2id
		local matchResult = match.winner == 0 and 'd' or opponent.placement == 1 and 'w' or 'l'
		opponentRoundData.scoreboard.match[matchResult] = (opponentRoundData.scoreboard.match[matchResult] or 0) + 1
	end)
end

return StandingsParseLpdb
