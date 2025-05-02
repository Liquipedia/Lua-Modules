---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local AgentNames = require('Module:AgentNames')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Lua = require('Module:Lua')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {
	OPPONENT_CONFIG = {
		disregardTransferDates = true,
	}
}
local MapFunctions = {}

MatchFunctions.DEFAULT_MODE = 'team'

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

--
-- match related functions
--

---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

-- These maps however shouldn't be stored
-- The keepMap function will check if a map should be kept
---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, MapFunctions.keepMap)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
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

---@param match table
---@param map table
---@param opponents table[]
---@return table<string, any>
function MapFunctions.getExtraData(match, map, opponents)
	---@type table<string, any>
	local extraData = {
		t1firstside = map.t1firstside,
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
	}

	for opponentIdx, opponent in ipairs(map.opponents) do
		for playerIdx, player in pairs(opponent.players) do
			extraData['t' .. opponentIdx .. 'p' .. playerIdx] = player.player
			extraData['t' .. opponentIdx .. 'p' .. playerIdx .. 'agent'] = player.agent
		end
	end

	return extraData
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, AgentNames)

	local players = Array.mapIndexes(function(playerIndex)
		return map['t' .. opponentIndex .. 'p' .. playerIndex]
	end)
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			local data = Json.parseIfString(map['t' .. opponentIndex .. 'p' .. playerIndex])
			return data and {name = data.player} or nil
		end,
		function(playerIndex, playerIdData, playerInputData)
			local stats = Json.parseIfString(map['t'.. opponentIndex .. 'p' .. playerIndex]) or {}
			return {
				kills = stats.kills,
				deaths = stats.deaths,
				assists = stats.assists,
				acs = stats.acs,
				player = playerIdData.name or playerInputData.name,
				agent = getCharacterName(stats.agent),
			}
		end
	)
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	return function(opponentIndex)
		if not map['t'.. opponentIndex ..'atk'] and not map['t'.. opponentIndex ..'def'] then
			return
		end
		return (tonumber(map['t'.. opponentIndex ..'atk']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'def']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'otatk']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'otdef']) or 0)
	end
end

return CustomMatchGroupInput
