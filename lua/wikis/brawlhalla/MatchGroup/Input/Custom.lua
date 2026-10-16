---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterStandardization = Lua.import('Module:CharacterStandardization', {loadData = true})
local FnUtil = Lua.import('Module:FnUtil')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}

---@class BrawlhallaMatchParser: MatchParserInterface
local MatchFunctions = {
	getBestOf = MatchGroupInputUtil.getBestOf,
	DEFAULT_NODE = 'singles',
	DATE_FALLBACKS = {
		'tournament_enddate',
		'tournament_startdate',
	},
}

---@class BrawlhallaMapParser: MapParserInterface
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
	end)
end


---@param maps table[]
---@return fun(opponentIndex: integer): integer
function MatchFunctions.calculateMatchScore(maps)
	return FnUtil.curry(MatchGroupInputUtil.computeMatchScoreFromMapWinners, maps)
end

---@param map table
---@param opponent MGIParsedOpponent
---@param opponentIndex integer
---@return {char: string, player: string}[]?
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	if opponent.type == Opponent.solo then
		return MapFunctions._processSoloMapData(opponent.match2players[1], map, opponentIndex)
	elseif opponent.type == Opponent.duo then
		return Array.map(opponent.match2players, function (player, playerIndex)
			local scoreInput = map['o' .. opponent .. 'score' .. playerIndex]
			return {
				char = MatchGroupInputUtil.getCharacterName(
					CharacterStandardization, map['o' .. opponent .. 'char' .. playerIndex]
				),
				player = player.name,
				score = tonumber(scoreInput) or scoreInput
			}
		end)
	end

	return nil
end

---@param player MGIParsedPlayer
---@param map table
---@param opponentIndex integer
---@return {char: string, player: string}[]
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
		if map['o' .. opponentIndex .. 'score' .. 1] then
			local sum = tonumber(map['o' .. opponentIndex .. 'score' .. 1])
			for i = 2, math.huge do
				local score = tonumber(map['o' .. opponentIndex .. 'score' .. i])
				if score == nil then
					return sum
				end
				sum = sum + score
			end
		elseif not winner then
			-- TODO Better to check if map has started, rather than finished, for a more correct handling
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
