---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local AgentNames = require('Module:AgentNames')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Lua = require('Module:Lua')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

---@class ValorantNormalMapParser: MapParserInterface
local MapFunctions = {}

---@param map table
---@return table
function MapFunctions.getMap(map)
	return map
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

return MapFunctions
