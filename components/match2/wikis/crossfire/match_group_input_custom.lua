---
-- @Liquipedia
-- wiki=crossfire
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local DEFAULT_BESTOF = 3
local DEFAULT_MODE = 'team'
local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	maxNumPlayers = 5
}

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)

	local games = MatchFunctions.extractMaps(match, #opponents)

	match.bestof = MatchFunctions.getBestOf(match.bestof)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games)
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
		MatchGroupInputUtil.setPlacement(opponents, match.winner, 1, 2, match.resulttype)
	end

	MatchFunctions.getTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match)

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end

CustomMatchGroupInput.processMap = FnUtil.identity

--
-- match related functions
--

---@param match table
---@param opponentCount integer
---@return table[]
function MatchFunctions.extractMaps(match, opponentCount)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = MapFunctions.getExtraData(map, opponentCount)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
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

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput)

	if bestof then
		Variables.varDefine('bestof', bestof)
		return bestof
	end

	return tonumber(Variables.varDefault('bestof')) or DEFAULT_BESTOF
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE)
	return MatchGroupInputUtil.getCommonTournamentVars(match)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	return {}
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mvp = MatchGroupInputUtil.readMvp(match),
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end

--
-- map related functions
--

---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(map, opponentCount)
	return {
		comment = map.comment,
		header = map.header,
	}
end

return CustomMatchGroupInput
