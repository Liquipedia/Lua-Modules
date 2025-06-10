---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')

local CustomMatchGroupInput = {}
local MapFunctions = {}
CustomMatchGroupInput.OPPONENT_CONFIG = {
	resolveRedirect = true,
	applyUnderScores = true,
	maxNumPlayers = 10,
}
CustomMatchGroupInput.DEFAULT_MODE = 'singles'
CustomMatchGroupInput.DATE_FALLBACKS = {
	'tournament_enddate',
	'tournament_startdate',
}


-- called from Module:MatchGroup
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

---@param bestofInput string
---@return integer?
function CustomMatchGroupInput.getBestOf(bestofInput)
	return tonumber(bestofInput)
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
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	if opponent.type == Opponent.literal then
		return {}
	end

	return MapFunctions._processPlayerMapData(map, opponent, opponentIndex)
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions._processPlayerMapData(map, opponent, opponentIndex)
	local game = Game.toIdentifier{game = Variables.varDefault('tournament_game')}
	local CharacterStandardizationData = mw.loadData('Module:CharacterStandardization/' .. game)

	local players = Array.mapIndexes(function(playerIndex)
		return map['t' .. opponentIndex .. 'p' .. playerIndex] or map['o' .. opponentIndex .. 'p' .. playerIndex]
	end)

	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			if Opponent.typeIsParty(opponent.type) then
				return {name = (opponent.match2players[playerIndex] or {}).name}
			end
			return {name = map['t' .. opponentIndex .. 'p' .. playerIndex]}
		end,
		function(playerIndex, playerIdData, playerInputData)
			local charInputs = Json.parseIfTable(map['o' .. opponentIndex .. 'p' .. playerIndex]) or {} ---@type string[]
			local characters = Array.map(charInputs, function(characterInput)
				local character = MatchGroupInputUtil.getCharacterName(CharacterStandardizationData, characterInput)
				if not character then
					return nil
				end

				return {name = character}
			end)
			return {
				characters = characters,
				player = playerIdData.name,
			}
		end
	)
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

return CustomMatchGroupInput
