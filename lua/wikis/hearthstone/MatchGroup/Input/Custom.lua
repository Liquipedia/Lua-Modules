---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterStandardization = mw.loadData('Module:CharacterStandardization')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local CustomMatchGroupInput = {}
local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	pagifyPlayerNames = true,
}

local MatchFunctions = {
	OPPONENT_CONFIG = OPPONENT_CONFIG,
}
local MapFunctions = {
	ADD_SUB_GROUP = true,
}

local FffMatchFunctions = {
	OPPONENT_CONFIG = OPPONENT_CONFIG,
}
local FfaMapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, FffMatchFunctions)
end

--- Normal 2 opponent match

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	return tonumber(bestofInput)
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return Table.filterByKey(match, function(key) return key:match('subgroup%d+header') end)
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local extradata = {}

	Array.forEach(opponents, function(_, opponentIndex)
		local prefix = 'o' .. opponentIndex .. 'c'
		local classes = Array.mapIndexes(function(classIndex)
			return Logic.nilIfEmpty(map[prefix .. classIndex])
		end)
		Array.forEach(classes, function(class, classIndex)
			extradata[prefix .. classIndex] = MapFunctions.readCharacter(class)
		end)
	end)

	return extradata
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

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return table[]?
function MapFunctions.getPlayersOfMapOpponent(mapInput, opponent, opponentIndex)
	if opponent.type == Opponent.literal then
		return
	elseif opponent.type == Opponent.team then
		return MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex)
	end
	return MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex)
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return {character: string?, player: string}[]
function MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex)
	local oppPrefix = 'o' .. opponentIndex

	local players = Array.mapIndexes(function(playerIndex)
		return Logic.nilIfEmpty(mapInput[oppPrefix .. 'p' .. playerIndex])
			or Logic.nilIfEmpty(mapInput[oppPrefix .. 'c' .. playerIndex])
	end)

	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			local prefix = oppPrefix .. 'p' .. playerIndex
			return {
				name = mapInput[prefix],
				link = Logic.nilIfEmpty(mapInput[prefix .. 'link']),
			}
		end,
		function(playerIndex, playerIdData, playerInputData)
			return {
				player = playerIdData.name or playerInputData.link,
				class = MapFunctions.readCharacter(Logic.nilIfEmpty(mapInput[oppPrefix .. 'c' .. playerIndex])),
			}
		end
	)
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return table<string, {character: string?, player: string}>
function MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	local prefix = 'o' .. opponentIndex .. 'c'

	return Array.map(players, function(player, playerIndex)
		return {
			player = player.name,
			class = MapFunctions.readCharacter(mapInput[prefix .. playerIndex]),
		}
	end)
end

MapFunctions.readCharacter = FnUtil.curry(MatchGroupInputUtil.getCharacterName, CharacterStandardization)

--- FFA Match

---@param match table
---@param opponents table[]
---@param scoreSettings table
---@return table[]
function FffMatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, FfaMapFunctions)
end

---@param opponents table[]
---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function FffMatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@param settings table
---@return table
function FffMatchFunctions.getExtraData(match, games, opponents, settings)
	return {
		placementinfo = settings.placementInfo,
		settings = settings.settings,
	}
end

return CustomMatchGroupInput
