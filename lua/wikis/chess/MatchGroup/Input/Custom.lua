---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')

local Eco = Lua.import('Module:ChessOpenings')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}

---@class ChessMatchParser: MatchParserInterface
local MatchFunctions = {
	DEFAULT_MODE = 'solo',
	getBestOf = MatchGroupInputUtil.getBestOf,
}

---@class ChessMapParser: MapParserInterface
local MapFunctions = {}

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

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return (map.winner == opponentIndex and 1 or map.winner == 0 and 0.5 or 0)
		end), Operator.add)
	end
end

---@param match table
---@param games table[]
---@return table
function MatchFunctions.getLinks(match, games)
	---@type table<string, string|table|nil>
	local links = MatchGroupInputUtil.getLinks(match)

	Array.forEach(games, function(game, gameIndex)
		local gameLinks = MatchGroupInputUtil.getLinks(game)
		for key, link in pairs(gameLinks) do
			if type(links[key]) ~= 'table' then
				links[key] = {[0] = links[key]}
			end
			links[key][gameIndex] = link
		end
	end)

	return links
end

--
-- map related functions
--

---@param map table
---@param opponent MGIParsedOpponent
---@param opponentIndex integer
---@return table[]?
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	if opponent.type == Opponent.literal then
		return
	elseif opponent.type == Opponent.solo then
		local player = opponent.match2players[1]
		return {
			{
				player = player.name,
				displayName = player.displayname,
				flag = player.flag,
			},
		}
	end
	local mapPlayersInput = Array.mapIndexes(function (index)
		local mapPlayerInput = map['t' .. opponentIndex .. 'p' .. index]
		if String.isEmpty(mapPlayerInput) then
			return nil
		end
		return {player = map['t' .. opponentIndex .. 'p' .. index]}
	end)
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		mapPlayersInput,
		function (playerIndex)
			local participant = mapPlayersInput[playerIndex]
			return participant and {name = participant.player} or nil
		end,
		function (playerIndex, playerIdData, playerInputData)
			return {
				player = playerIdData.name or playerInputData.link or playerInputData.name,
				displayName = playerIdData.displayname or playerInputData.name,
				flag = playerIdData.flag,
			}
		end
	)
end

---@param match table
---@param map table
---@param opponents MGIParsedOpponent[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return {
		eco = Eco.sanitise(map.eco),
	}
end

---@param map table
---@param opponentIndex integer
---@return table
function MapFunctions.extendMapOpponent(map, opponentIndex)
	local whiteSide = tonumber(map.white)
	return {
		color = (whiteSide == opponentIndex and 'white')
			or (whiteSide ~= nil and 'black')
			or nil
	}
end

return CustomMatchGroupInput
