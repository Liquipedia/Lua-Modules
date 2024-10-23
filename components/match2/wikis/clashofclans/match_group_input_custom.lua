---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MathUtil = require('Module:MathUtil')
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
	match.links = MatchGroupInputUtil.getLinks(match)

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
		match.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
		match.winner = MatchGroupInputUtil.getWinner(match.status, winnerInput, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.status, match.winner, opponentIndex)
		end)
	end

	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE)
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)

	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end

--
-- match related functions
--

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mvp = MatchGroupInputUtil.readMvp(match),
	}
end

---@param match table
---@param opponentCount integer
---@return table[]
function MatchFunctions.extractMaps(match, opponentCount)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.map = nil
		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			return {
				score = score,
				status = status,
				time = map.extradata.times[opponentIndex],
				percentage = map.extradata.percentages[opponentIndex] or 0
			}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, opponentInfo)
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

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

--
-- map related functions
--

---@param map table
---@return table
function MapFunctions.getExtraData(map)
	return {
		comment = map.comment,
		times = MapFunctions.readTimes(map),
		percentages = MapFunctions.readPercentages(map),
	}
end

---@param map table
---@return table
function MapFunctions.readPercentages(map)
	local percentages = {}

	for _, percentage in Table.iter.pairsByPrefix(map, 'percent') do
		table.insert(percentages, tonumber(percentage) or 0)
	end

	return percentages
end

---@param map table
---@return table
function MapFunctions.readTimes(map)
	local timesInSeconds = {}

	for _, timeInput in Table.iter.pairsByPrefix(map, 'time') do
		local timeFragments = Array.map(
			Array.reverse(mw.text.split(timeInput, ':', true)),
			function(number, index)
				number = tonumber(number)
				return number and ((60 ^ (index - 1)) * number) or number
			end
		)

		table.insert(timesInSeconds, MathUtil.sum(timeFragments))
	end

	return timesInSeconds
end

return CustomMatchGroupInput
