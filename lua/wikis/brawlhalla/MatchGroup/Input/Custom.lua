---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterStandardization = mw.loadData('Module:CharacterStandardization')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')

local CustomMatchGroupInput = {}
local MapFunctions = {}
CustomMatchGroupInput.getBestOf = MatchGroupInputUtil.getBestOf
CustomMatchGroupInput.DEFAULT_NODE = 'singles'
CustomMatchGroupInput.DATE_FALLBACKS = {
	'tournament_enddate',
	'tournament_startdate',
}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, CustomMatchGroupInput)
end

---@param match table
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param games table[]
---@return table[]
function CustomMatchGroupInput.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
	end)
end


---@param maps table[]
---@return fun(opponentIndex: integer): integer
function CustomMatchGroupInput.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return {players: {char: string, player: string}[]}?
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	if opponent.type == Opponent.solo then
		return MapFunctions._processSoloMapData(opponent.match2players[1], map, opponentIndex)
	end
	return nil
end

---@param player table
---@param map table
---@param opponentIndex integer
---@return {players: {char: string, player: string}[]}
function MapFunctions._processSoloMapData(player, map, opponentIndex)
	local char = map['char' .. opponentIndex] or ''

	return {
		{
			char = MatchGroupInputUtil.getCharacterName(CharacterStandardization, char),
			player = player.name,
		}
	}
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

---@param map table
---@param mapIndex integer
---@param match table
---@return string?
---@return string?
function MapFunctions.getMapName(map, mapIndex, match)
	if String.isNotEmpty(map.map) and map.map ~= 'TBD' then
		return mw.ext.TeamLiquidIntegration.resolve_redirect(map.map)
	end
	return map.map
end

return CustomMatchGroupInput
