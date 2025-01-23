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
---@param scoreMapper? fun(opponent: match2opponent): number?
---@return {rounds: {specialstatus: string, scoreboard: {points: number?}?}[]?, opponent: standardOpponent}[]
function StandingsParseLpdb.importFromMatches(rounds, scoreMapper)
	if not scoreMapper then
		scoreMapper = function(opponent)
			if opponent.status == 'S' then
				return tonumber(opponent.score)
			end
			return nil
		end
	end
	local matchIds = Array.flatMap(rounds, function(round)
		return round.matches
	end)

	local matchIdToRound = {}
	Array.forEach(rounds, function(round)
		Array.forEach(round.matches, function(match)
			matchIdToRound[match] = round.roundNumber
		end)
	end)

	local conditionsMatches = Condition.Tree(Condition.BooleanOperator.any)
	Array.forEach(matchIds, function(match)
		conditionsMatches:add(Condition.Node(Condition.ColumnName('match2id'), Condition.Comparator.eq, match))
	end)

	local opponents = {}
    Lpdb.executeMassQuery(
		'match2',
		{
			conditions = conditionsMatches:toString(),
			query = 'match2opponents',
		},
		function(match2)
			local roundNumber = matchIdToRound[match2.match2id]
			StandingsParseLpdb.parseMatch(roundNumber, match2, opponents, scoreMapper, #rounds)
		end
	)

	return Array.map(opponents, function(opponentData)
		return {
			opponent = Opponent.fromMatch2Record(opponentData.opponent),
			rounds = Array.map(opponentData.rounds, function(roundData)
				return {
					scoreboard = {
						points = roundData.scoreboard.points,
					},
					specialstatus = roundData.specialstatus or 'nc',
				}
			end)
		}
	end)
end

---@param opponentData match2opponent
---@param maxRounds integer
---@return {rounds: {specialstatus: string, scoreboard: {points: number?}?}[]?, opponent: match2opponent}
function StandingsParseLpdb.newOpponent(opponentData, maxRounds)
	return {
		opponent = opponentData,
		rounds = Array.map(Array.range(1, maxRounds), function()
			return {
				scoreboard = {},
			}
		end)
	}
end

---@param roundNumber integer
---@param match match2
---@param opponents {rounds: {specialstatus: string, scoreboard: {points: number?}?}[]?, opponent: match2opponent}[]
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
		opponentRoundData.scoreboard.points = scoreMapper(opponent)
		opponentRoundData.specialstatus = ''
	end)
end

return StandingsParseLpdb
