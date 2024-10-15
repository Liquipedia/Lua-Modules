---
-- @Liquipedia
-- wiki=smite
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local GodNames = mw.loadData('Module:GodNames')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local DEFAULT_BESTOF = 3
local DEFAULT_MODE = 'team'
local MAX_NUM_PLAYERS = 15
local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	maxNumPlayers = MAX_NUM_PLAYERS,
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
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.resulttype, match.winner, opponentIndex)
		end)
	end

	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE)
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match)

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end

--
-- match related functions
--

---@param match table
---@param opponentCount integer
---@return table[]
function MatchFunctions.extractMaps(match, opponentCount)
	local maps = {}

	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		table.insert(maps, MapFunctions.readMap(map, opponentCount))
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

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	return {
		stats = match.stats,
		smiteesports = match.smiteesports and ('https://www.smiteesports.com/matches/' .. match.smiteesports) or nil,
	}
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end

--
-- map related functions
--

---@param map table
---@param opponentCount integer
---@return table?
function MapFunctions.readMap(map, opponentCount)
	local finishedInput = map.finished --[[@as string?]]
	local winnerInput = map.winner --[[@as string?]]

	if not MapFunctions.keepMap(map) then
		map.map = nil
	end

	if Logic.isDeepEmpty(map) then
		return nil
	end

	map.extradata = MapFunctions.getExtraData(map, opponentCount)
	map.finished = MatchGroupInputUtil.mapIsFinished(map)

	local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
		local score, status = MatchGroupInputUtil.computeOpponentScore({
			walkover = map.walkover,
			winner = map.winner,
			opponentIndex = opponentIndex,
			score = map['score' .. opponentIndex],
		}, MapFunctions.calculateMapScore(map.winner, map.finished))
		return {score = score, status = status}
	end)

	map.scores = Array.map(opponentInfo, Operator.property('score'))
	if map.finished then
		map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
		map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
	end

	return map
end

-- Check if a map should be discarded due to being redundant
---@param map table
---@return boolean
function MapFunctions.keepMap(map)
	return map.map ~= nil
end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(map, opponentCount)
	return Table.merge({
		comment = map.comment,
		team1side = string.lower(map.team1side or ''),
		team2side = string.lower(map.team2side or ''),
	}, MapFunctions.getPicksAndBans(map, opponentCount))
end

---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getPicksAndBans(map, opponentCount)
	local godData = {}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, GodNames)
	for opponentIndex = 1, opponentCount do
		for playerIndex = 1, MAX_NUM_PLAYERS do
			local god = map['t' .. opponentIndex .. 'g' .. playerIndex]
			godData['team' .. opponentIndex .. 'god' .. playerIndex] = getCharacterName(god)

			local ban = map['t' .. opponentIndex .. 'b' .. playerIndex]
			godData['team' .. opponentIndex .. 'ban' .. playerIndex] = getCharacterName(ban)
		end
	end

	return godData
end

return CustomMatchGroupInput
