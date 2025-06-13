---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Ordinal = require('Module:Ordinal')
local Operator = require('Module:Operator')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local CustomMatchGroupInput = {}
CustomMatchGroupInput.DEFAULT_MODE = 'solo'

local MapFunctions = {
	BREAK_ON_EMPTY = true,
}

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
					local scores = Array.map(map.opponents, Operator.property('score'))
					return scores[opponentIndex] or 0
				end), Operator.add, 0)
			elseif calculateBy == 'penalties' then
				return (Array.filter(maps, function(map)
					return Logic.readBool(map.penalty)
				end)[1].opponents[opponentIndex] or {}).score
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
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
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
		hassubmatches = tostring(hasSubmatches),
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
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local players = Array.mapIndexes(function(playerIndex)
		return map['t' .. opponentIndex .. 'p' .. playerIndex]
	end)
	return MatchGroupInputUtil.parseMapPlayers(
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
end

---@param map table
---@param mapIndex integer
---@param match table
---@return string
---@return string?
function MapFunctions.getMapName(map, mapIndex, match)
	if Logic.readBool(match.hasSubmatches) then
		-- generic map name (not displayed)
		return 'Game ' .. mapIndex
	elseif Logic.readBool(map.penalty) then
		return 'Penalties'
	else
		return mapIndex .. Ordinal.suffix(mapIndex) .. ' Leg'
	end
end

---@param match table
---@param map table
---@param opponents table[]
---@return string
function MapFunctions.getMapMode(match, map, opponents)
	return Opponent.toMode(opponents[1].type, opponents[2].type)
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return {
		penaltyscores = CustomMatchGroupInput._submatchPenaltyScores(map, opponents, Logic.readBool(match.hasSubmatches)),
	}
end

return CustomMatchGroupInput
