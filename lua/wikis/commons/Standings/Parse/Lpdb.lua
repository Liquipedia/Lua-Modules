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

---Slim match struct carrying only the fields consumed by standings tiebreakers and import.
---Dropped: bracketData, extradata, full game payloads.
---@class StandingsImportMatch
---@field matchId string
---@field finished boolean
---@field winner integer?
---@field opponents standardOpponent[] -- by reference from matchFromRecord
---@field games {winner: integer?, status: string?, scores: table?}[]

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
		function(record)
			local match2 = MatchGroupUtil.matchFromRecord(record)
			---@type StandingsImportMatch
			local slimMatch = {
				matchId = match2.matchId,
				finished = match2.finished,
				winner = match2.winner,
				opponents = match2.opponents,
				games = Array.map(match2.games, function(game)
					return {winner = game.winner, status = game.status, scores = game.scores}
				end),
			}
			local roundNumbers = matchIdToRound[record.match2id]
			Array.forEach(roundNumbers, function(roundNumber)
				StandingsParseLpdb.parseMatch(roundNumber, slimMatch, opponents, scoreMapper, #rounds)
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

---@param roundNumber integer
---@param slimMatch StandingsImportMatch
---@param opponents StandingTableOpponentData[]
---@param scoreMapper fun(opponent: standardOpponent): number?
---@param maxRounds integer
function StandingsParseLpdb.parseMatch(roundNumber, slimMatch, opponents, scoreMapper, maxRounds)
	Array.forEach(slimMatch.opponents, function(opponent)
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
		local points = scoreMapper(opponent)
		if points then
			opponentRoundData.scoreboard.points = (opponentRoundData.scoreboard.points or 0) + points
		end
		opponentRoundData.specialstatus = ''
		opponentRoundData.match = slimMatch
		if not slimMatch.finished then
			return
		end
		local matchResult = slimMatch.winner == 0 and 'd' or opponent.placement == 1 and 'w' or 'l'
		opponentRoundData.scoreboard.match[matchResult] = (opponentRoundData.scoreboard.match[matchResult] or 0) + 1
	end)
end

return StandingsParseLpdb
