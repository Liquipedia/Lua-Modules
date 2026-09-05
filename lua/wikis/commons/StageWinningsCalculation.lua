---
-- @Liquipedia
-- page=Module:StageWinningsCalculation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent/Custom')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local StageWinningsCalculation = {}

---@param props {matchGroupsSpecProps: table<string, string>, startDate: integer?, endDate: integer?, mode: string,
---startValue: number, valuePerWin: number, valueByScore: table<string, number>?,
---pointsStart: number, pointsPerWin: number, pointsByScore: table<string, number>?,
---points2Start: number, points2PerWin: number, points2ByScore: table<string, number>?,
---gameCountDefaultResult: number, hideWinnings: boolean}
---@return {opponent: standardOpponent, matchWins: integer, matchLosses: integer, matchDraws: integer,
---gameWins: integer, gameLosses: integer, winnings: number, scoreDetails: table<string, integer>,
---points: number, points2: number}[]
function StageWinningsCalculation.run(props)
	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = StageWinningsCalculation._buildConditions(props),
		query = 'match2opponents, winner',
		limit = 5000
	})
	matches = Array.filter(matches, function(match)
		return #match.match2opponents == 2
	end)

	local byName = {}

	Array.forEach(matches, function(match)
		match.opponents = Array.map(match.match2opponents, Opponent.fromMatch2Record)
		Array.forEach(match.opponents, function(opponent, opponentIndex)
			local identifier = Opponent.toName(opponent)
			opponent.name = identifier
			opponent.score = match.match2opponents[opponentIndex].score
			opponent.status = match.match2opponents[opponentIndex].status
			byName[identifier] = byName[identifier] or {
				opponent = opponent,
				scoreDetails = {},
				matchWins = 0,
				matchLosses = 0,
				matchDraws = 0,
				gameWins = 0,
				gameLosses = 0,
				winnings = 0,
				points = 0,
				points2 = 0,
			}
		end)

		local winnerId = tonumber(match.winner)

		local opponent1 = match.opponents[1]
		local opponent2 = match.opponents[2]

		local opponent1Score = Opponent.getScoreValue(opponent1)
		local opponent2Score = Opponent.getScoreValue(opponent2)

		local score = opponent1Score .. '-' .. opponent2Score
		local reversedScore = opponent2Score .. '-' .. opponent1Score

		byName[opponent1.name].scoreDetails[score] = (byName[opponent1.name].scoreDetails[score] or 0) + 1
		byName[opponent2.name].scoreDetails[reversedScore] = (byName[opponent2.name].scoreDetails[reversedScore] or 0) + 1

		if winnerId == 1 then
			byName[opponent1.name].matchWins = byName[opponent1.name].matchWins + 1
			byName[opponent2.name].matchLosses = byName[opponent2.name].matchLosses + 1
		elseif winnerId == 2 then
			byName[opponent2.name].matchWins = byName[opponent2.name].matchWins + 1
			byName[opponent1.name].matchLosses = byName[opponent1.name].matchLosses + 1
		else
			byName[opponent1.name].matchDraws = byName[opponent1.name].matchDraws + 1
			byName[opponent2.name].matchDraws = byName[opponent2.name].matchDraws + 1
		end

		local numberOfGamesForScoreValue = function(scoreValue)
			if Logic.isNumeric(scoreValue) then
				return tonumber(scoreValue)
			elseif Logic.isEmpty(scoreValue) or scoreValue ~= MatchGroupInputUtil.STATUS.DEFAULT_WIN then
				return 0
			end
			return props.gameCountDefaultResult
		end

		local gamesWonOpponent1 = numberOfGamesForScoreValue(opponent1Score)
		local gamesWonOpponent2 = numberOfGamesForScoreValue(opponent2Score)

		byName[opponent1.name].gameWins = byName[opponent1.name].gameWins + gamesWonOpponent1
		byName[opponent2.name].gameLosses = byName[opponent2.name].gameLosses + gamesWonOpponent1
		byName[opponent1.name].gameLosses = byName[opponent1.name].gameLosses + gamesWonOpponent2
		byName[opponent2.name].gameWins = byName[opponent2.name].gameWins + gamesWonOpponent2
	end)

	local opponents = Array.extractValues(byName)

	Array.forEach(opponents, function(opponent)
		if props.mode == 'matchWins' then
			opponent.winnings = props.startValue + opponent.matchWins * props.valuePerWin
			opponent.points = props.pointsStart + opponent.matchWins * props.pointsPerWin
			opponent.points2 = props.points2Start + opponent.matchWins * props.points2PerWin
			return
		elseif props.mode == 'gameWins' then
			opponent.winnings = props.startValue + opponent.gameWins * props.valuePerWin
			opponent.points = props.pointsStart + opponent.gameWins * props.pointsPerWin
			opponent.points2 = props.points2Start + opponent.gameWins * props.points2PerWin
			return
		end
		-- case: props.mode == 'scores'
		local winnings = props.startValue
		local points = props.pointsStart
		local points2 = props.points2Start
		for score, count in pairs(opponent.scoreDetails) do
			winnings = winnings + (props.valueByScore[score] or 0) * count
			points = points + (props.pointsByScore[score] or 0) * count
			points2 = points2 + (props.points2ByScore[score] or 0) * count
		end
		opponent.winnings = winnings
		opponent.points = points
		opponent.points2 = points2
	end)

	if props.hideWinnings then
		Array.sortInPlaceBy(opponents, function(opponent)
			return {- opponent.points, - opponent.points2, - opponent.matchWins, - opponent.gameWins, Opponent.toName(opponent)}
		end)
	else
		Array.sortInPlaceBy(opponents, function(opponent)
			return {- opponent.winnings, - opponent.matchWins, - opponent.gameWins, Opponent.toName(opponent)}
		end)
	end

	return opponents

end

---@param props {matchGroupsSpecProps: table<string, string>, startDate: integer?, endDate: integer?}
---@return string
function StageWinningsCalculation._buildConditions(props)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('finished'), Comparator.eq, '1'),
		ConditionNode(ColumnName('status'), Comparator.neq, 'notplayed'),
		ConditionNode(ColumnName('winner'), Comparator.neq, ''),
		TournamentStructure.getMatch2Filter(
			TournamentStructure.readMatchGroupsSpec(props.matchGroupsSpecProps)
			or TournamentStructure.currentPageSpec()
		),
	}

	if props.startDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, props.startDate))
	end

	if props.endDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.le, props.endDate))
	end

	return tostring(conditions)
end

return StageWinningsCalculation
