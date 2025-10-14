---
-- @Liquipedia
-- page=Module:StageWinningsCalculation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local StageWinningsCalculation = {}

---@param props {matchGroupId1: string?, tournament1: string, startDate: integer?, endDate: integer?, mode: string,
---startValue: number, valuePerWin: number, valueByScore: table<string, number>?}
---@return {opponent: standardOpponent, matchWins: integer, matchLosses: integer, gameWins: integer,
---gameLosses: integer, winnings: number, scoreDetails: table<string, integer>}[]
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
		Array.forEach(match.opponents, function(opponent)
			local identifier = Opponent.toName(opponent)
			byName[identifier] = byName[identifier] or {
				opponent = opponent,
				scoreDetails = {},
				matchWins = 0,
				matchLosses = 0,
				gameWins = 0,
				gameLosses = 0,
				winnings = 0,
			}
		end)

		local winnerId = tonumber(match.winner)
		if winnerId ~= 1 and winnerId ~= 2 then return end
		local loserId = 3 - winnerId

		local winner = match.opponents[winnerId]
		local loser = match.opponents[loserId]

		local winnerScore = OpponentDisplay.InlineScore(winner)
		local loserScore = OpponentDisplay.InlineScore(loser)

		local score = winnerScore .. '-' .. loserScore
		local reversedScore = loserScore .. '-' .. winnerScore

		byName[winner.name].scoreDetails[score] = (byName[winner.name].scoreDetails[score] or 0) + 1
		byName[loser.name].scoreDetails[reversedScore] = (byName[loser.name].scoreDetails[reversedScore] or 0) + 1

		byName[winner.name].matchWins = byName[winner.name].matchWins + 1
		byName[loser.name].matchLosses = byName[loser.name].matchLosses + 1

		byName[winner.name].gameWins = byName[winner.name].gameWins + (tonumber(winner.score) or 0)
		byName[loser.name].gameLosses = byName[loser.name].gameLosses + (tonumber(winner.score) or 0)
		byName[winner.name].gameLosses = byName[winner.name].gameLosses + (tonumber(loser.score) or 0)
		byName[loser.name].gameWins = byName[loser.name].gameWins + (tonumber(loser.score) or 0)
	end)

	local opponents = Array.extractValues(byName)

	Array.forEach(opponents, function(opponent)
		if props.mode == 'matchWins' then
			opponent.winnings = props.startValue + opponent.matchWins * props.valuePerWin
			return
		elseif props.mode == 'gameWins' then
			opponent.winnings = props.startValue + opponent.gameWins * props.valuePerWin
			return
		end
		-- case: props.mode == 'scores'
		local winnings = props.startValue
		for score, count in pairs(opponent.scoreDetails) do
			winnings = winnings + (props.valueByScore[score] or 0) * count
		end
		opponent.winnings = winnings
	end)

	Array.sortInPlaceBy(opponents, function(opponent)
		return {- opponent.winnings, - opponent.matchWins, - opponent.gameWins, Opponent.toName(opponent)}
	end)

	return opponents

end

---@param props {matchGroupId1: string?, tournament1: string, startDate: integer?, endDate: integer?}
---@return string
function StageWinningsCalculation._buildConditions(props)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('finished'), Comparator.eq, '1'),
		ConditionNode(ColumnName('status'), Comparator.neq, 'notplayed'),
		ConditionNode(ColumnName('winner'), Comparator.neq, ''),
		TournamentStructure.getMatch2Filter(
			TournamentStructure.readMatchGroupsSpec(props)
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
