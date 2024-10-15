---
-- @Liquipedia
-- wiki=easportsfc
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Ordinal = require('Module:Ordinal')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Streams = Lua.import('Module:Links/Stream')
local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local winnerInput = match.winner --[[@as string?]]
	local finishedInput = match.finished --[[@as string?]]

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, {})
	end)

	local games = CustomMatchGroupInput.extractMaps(match, opponents)

	local scoreType = 'mapScores'
	if Logic.readBool(match.hasSubmatches) then
		scoreType = 'mapWins'
	elseif Array.any(Array.map(games, Operator.property('penalty')), Logic.readBool) then
		scoreType = 'penalties'
	end
	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and CustomMatchGroupInput.calculateMatchScore(games, scoreType)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = winnerInput,
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
	match.extradata = CustomMatchGroupInput.getExtraData(match, scoreType == 'mapWins')

	match.games = games
	match.opponents = opponents

	return match
end

---@param match table
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	local maps = {}
	for mapKey, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if Table.isEmpty(map) then
			break
		end
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		if Logic.readBool(match.hasSubmatches) then
			-- generic map name (not displayed)
			map.map = 'Game ' .. mapIndex
		elseif Logic.readBool(map.penalty) then
			map.map = 'Penalties'
		else
			map.map = mapIndex .. Ordinal.suffix(mapIndex) .. ' Leg'
		end

		map.mode = Opponent.toMode(opponents[1].type, opponents[2].type)
		map.extradata = CustomMatchGroupInput.getMapExtraData(map, opponents, Logic.readBool(match.hasSubmatches))

		map.opponents = CustomMatchGroupInput.getParticipants(map, opponents)

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		local opponentInfo = Array.map(opponents, function(_, opponentIndex)
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
		match[mapKey] = nil
	end

	return maps
end

--- TODO: Investigate if some parts of this should be a display rather than storage.
--- If penalties is supplied, than one map MUST have the penalty flag set to true.
---@param maps table[]
---@param calculateBy 'mapWins'|'mapScores'|'penalties'
---@return fun(opponentIndex: integer): integer
function CustomMatchGroupInput.calculateMatchScore(maps, calculateBy)
	return function(opponentIndex)
		if calculateBy == 'mapWins' then
			return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
		elseif calculateBy == 'mapScores' then
			return Array.reduce(Array.map(maps, function(map)
				return map.scores[opponentIndex] or 0
			end), Operator.add, 0)
		elseif calculateBy == 'penalties' then
			return Array.filter(maps, function(map)
				return Logic.readBool(map.penalty)
			end)[1].scores[opponentIndex]
		else
			error('Unknown calculateBy: ' .. tostring(calculateBy))
		end
	end
end

---@param match table
---@param hasSubmatches boolean
---@return table
function CustomMatchGroupInput.getExtraData(match, hasSubmatches)
	return {
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
		hassubmatches = tostring(hasSubmatches),
	}
end

---@param map table
---@param opponents table[]
---@param hasSubmatches boolean
---@return table
function CustomMatchGroupInput.getMapExtraData(map, opponents, hasSubmatches)
	return {
		comment = map.comment,
		penaltyscores = CustomMatchGroupInput._submatchPenaltyScores(map, opponents, hasSubmatches),
	}
end

---@param map table
---@param opponents table[]
---@param hasSubmatches boolean
---@return integer[]?
function CustomMatchGroupInput._submatchPenaltyScores(map, opponents, hasSubmatches)
	if not hasSubmatches then
		return
	end

	local hasPenalties = false
	local scores = Array.map(opponents, function(_, opponentIndex)
		local score = tonumber(map['penaltyScore' .. opponentIndex])
		hasPenalties = hasPenalties or (score ~= nil)
		return score or 0
	end)

	return hasPenalties and scores or nil
end

---@param map table
---@param opponents MGIParsedOpponent[]
---@return {players: table[]}[]
function CustomMatchGroupInput.getParticipants(map, opponents)
	return Array.map(opponents, function(opponent, opponentIndex)
		local players = Array.mapIndexes(function(playerIndex)
			return map['t' .. opponentIndex .. 'p' .. playerIndex]
		end)
		local participants, _ = MatchGroupInputUtil.parseParticipants(
			opponent.match2players,
			players,
			function(playerIndex)
				local data = map['t' .. opponentIndex .. 'p' .. playerIndex]
				return data and {name = data} or nil
			end,
			function(playerIndex, playerIdData, playerInputData)
				return {
					played = true
				}
			end
		)
		return {players = participants}
	end)
end

return CustomMatchGroupInput
