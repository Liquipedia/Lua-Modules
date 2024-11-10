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

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local CustomMatchGroupInput = {}
CustomMatchGroupInput.DEFAULT_MODE = 'solo'

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	--- TODO: Investigate if some parts of this should be a display rather than storage.
	--- If penalties is supplied, than one map MUST have the penalty flag set to true.
	---@param maps table[]
	---@return fun(opponentIndex: integer): integer
	CustomMatchGroupInput.calculateMatchScore = function(maps)
		local calculateBy = CustomMatchGroupInput.getScoreType(match, maps)
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

	return MatchGroupInputUtil.standardProcessMatch(match, CustomMatchGroupInput)
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

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		map.opponents = Array.map(opponents, function(opponent, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			local players = CustomMatchGroupInput.getPlayersOfMapOpponent(map, opponent, opponentIndex)
			return {score = score, status = status, players = players}
		end)

		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		table.insert(maps, map)
		match[mapKey] = nil
	end

	return maps
end

---@param bestOfInput string?
---@return integer?
function CustomMatchGroupInput.getBestOf(bestOfInput)
	return tonumber(bestOfInput)
end

---@param match table
---@param games table[]
---@return 'mapWins'|'mapScores'|'penalties'
function CustomMatchGroupInput.getScoreType(match, games)
	if Logic.readBool(match.hasSubmatches) then
		return 'mapWins'
	elseif Array.any(Array.map(games, Operator.property('penalty')), Logic.readBool) then
		return 'penalties'
	else
		return 'mapScores'
	end
end

---@param match table
---@param maps table[]
---@return table
function CustomMatchGroupInput.getExtraData(match, maps)
	local hasSubmatches = CustomMatchGroupInput.getScoreType(match, maps) == 'mapWins'
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
---@param opponent table
---@param opponentIndex integer
---@return table[]
function CustomMatchGroupInput.getPlayersOfMapOpponent(map, opponent, opponentIndex)
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
	return participants
end

return CustomMatchGroupInput
