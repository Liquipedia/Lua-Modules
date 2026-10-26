---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local CustomMatchGroupInput = {}

local MAX_NUM_PLAYERS = 5

---@class EvaMatchParser: MatchParserInterface
local MatchFunctions = {
	DEFAULT_MODE = 'team',
	getBestOf = MatchGroupInputUtil.getBestOf,
}

---@class EvaMapParser: MapParserInterface
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

-- "Normal" match
---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return FnUtil.curry(MatchGroupInputUtil.computeMatchScoreFromMapWinners, maps)
end

---@param match table
---@param games table[]
---@param opponents MGIParsedOpponent[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

---@param game table
---@param opponent MGIParsedOpponent
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(game, opponent, opponentIndex)
	local playersInput = Array.mapRange(
		1,
		Opponent.partySize(opponent.type) or MAX_NUM_PLAYERS,
		function (playerIndex)
			local playerData = Json.parseIfTable(game['t' .. opponentIndex .. 'p' .. playerIndex])
			if Logic.isEmpty(playerData) then
				return nil
			end
			---@cast playerData -nil
			return {
				player = playerData.player,
				score = tonumber(playerData.score),
				kills = tonumber(playerData.kills),
				deaths = tonumber(playerData.deaths),
				assists = tonumber(playerData.assists),
			}
		end
	)
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		playersInput,
		function (playerIndex)
			local playerInput = playersInput[playerIndex]
			return playerInput and {name = playerInput.player} or nil
		end,
		function(playerIndex, playerIdData, playerInputData)
			local playerInput = playersInput[playerIndex]
			playerInput.player = playerIdData.name or playerInputData.link or playerInputData.name
			return playerInput
		end
	)
end

return CustomMatchGroupInput
