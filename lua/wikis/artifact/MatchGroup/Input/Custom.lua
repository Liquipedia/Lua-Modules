---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local ChampionNames = mw.loadData('Module:ChampionNames')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {
	DEFAULT_MODE = 'solo',
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		pagifyTeamNames = true,
		maxNumPlayers = 10,
	},
	getBestOf = MatchGroupInputUtil.getBestOf,
}
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

--
-- match related functions
--

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

--
-- map related functions
--

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]?
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	if opponent.type ~= Opponent.solo then
		return nil
	end
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, ChampionNames)

	local heroes = Array.mapIndexes(function(playerIndex)
		return getCharacterName(map['p' .. opponentIndex .. 'h' .. playerIndex])
	end)

	return {
		[1] = {
			characters = heroes,
			deck = map['p' .. opponentIndex .. 'd'],
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

return CustomMatchGroupInput
