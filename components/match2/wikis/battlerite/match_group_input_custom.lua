---
-- @Liquipedia
-- wiki=battlerite
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	maxNumPlayers = 15,
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
	match.bestof = MatchGroupInputUtil.getBestOf(nil, games)
	games = MatchFunctions.removeUnsetMaps(games)
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

	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end

--
-- match related functions
--

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored
-- The keepMap function will check if a map should be kept
---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, MapFunctions.keepMap)
end

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

		map.opponents = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			return {score = score, status = status}
		end)

		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
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
function MatchFunctions.getExtraData(match)
	return {
		mvp = MatchGroupInputUtil.readMvp(match),
	}
end

--
-- map related functions
--

-- Check if a map should be discarded due to being redundant
---@param map table
---@return boolean
function MapFunctions.keepMap(map)
	return map.map ~= nil
end

---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(map, opponentCount)
	return {
		comment = map.comment,
	}
end

return CustomMatchGroupInput
