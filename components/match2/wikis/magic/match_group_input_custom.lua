---
-- @Liquipedia
-- wiki=magic
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local DEFAULT_BESTOF = 99

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@return table
function CustomMatchGroupInput.processMatch(match)
	if Logic.readBool(match.ffa) then
		error('FFA matches are not yet supported')
	end
	if CustomMatchGroupInput._hasTeamOpponent(match) then
		error('Team opponents are currently not yet supported on magic wiki')
	end

	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]
	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)
	local games = CustomMatchGroupInput.extractMaps(match, opponents)
	match.bestof = CustomMatchGroupInput.getBestOf(match)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and CustomMatchGroupInput.calculateMatchScore(games)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInputUtil.getWinner(match.resulttype, winnerInput, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.resulttype, match.winner, opponentIndex)
		end)
	end

	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'solo'))
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)

	match.games = games
	match.opponents = opponents

	return match
end

---@param match table
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	local maps = {}
	for key, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if not map.map then
			break
		end
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = {
			comment = map.comment,
		}
		map.map = 'Game ' .. mapIndex
		map.mode = Opponent.toMode(opponents[1].type, opponents[2].type)

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		local opponentInfo = Array.map(opponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, CustomMatchGroupInput.calculateMapScore(map.winner, map.finished))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function CustomMatchGroupInput.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return integer
function CustomMatchGroupInput.getBestOf(match)
	local bestOf = tonumber(Logic.emptyOr(match.bestof, Variables.varDefault('match_bestof')))
	Variables.varDefine('match_bestof', bestOf)
	return bestOf or DEFAULT_BESTOF
end

---@param match table
---@return boolean
function CustomMatchGroupInput._hasTeamOpponent(match)
	return match.opponent1.type == Opponent.team or match.opponent2.type == Opponent.team
end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function CustomMatchGroupInput.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

return CustomMatchGroupInput
