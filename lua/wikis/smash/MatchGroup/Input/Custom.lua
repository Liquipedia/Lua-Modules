---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterStandardizationData = Lua.import('Module:CharacterStandardization', {loadData = true})
local Game = Lua.import('Module:Game')
local Json = Lua.import('Module:Json')
local Variables = Lua.import('Module:Variables')

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

local DEFAULT_STOCK_COUNT = {
	melee = 4,
	brawl = 3,
	wiiu = 2,
	ultimate = 3,
	pm = 4,
	['64'] = 5,
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
	local function characterStatus(startingLife, remainingLife, pos, isLast)
		if remainingLife == -1 then
			return isLast and 1 or -1
		end
		return (startingLife - pos < remainingLife) and 1 or 0
	end

	local players = Array.mapIndexes(function(playerIndex)
		return map['o' .. opponentIndex .. 'p' .. playerIndex] or map['o' .. opponentIndex .. 'c' .. playerIndex]
	end)

	-- Input Format is "character,remainingLife,startingLife" per index
	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			if Opponent.typeIsParty(opponent.type) then
				return {name = opponent.match2players[playerIndex].name}
			end
			return {name = map['o' .. opponentIndex .. 'p' .. playerIndex]}
		end,
		function(playerIndex, playerIdData, playerInputData)
			local charInputs = Json.parseIfTable(map['o' .. opponentIndex .. 'c' .. playerIndex]) or {}
			local characters = Array.flatMap(charInputs, function(input)
				---@type [string, string?, string?]
				local splitInput = Array.parseCommaSeparatedString(input)
				local character = MatchGroupInputUtil.getCharacterName(CharacterStandardizationData, splitInput[1])
				if not character then
					return nil
				end
				local remainingLife, startingLife = tonumber(splitInput[2]) or 0, tonumber(splitInput[3]) or 1
				if splitInput[2] == '?' then
					remainingLife = -1
					startingLife = assert(
						tonumber(splitInput[3]) or DEFAULT_STOCK_COUNT[game],
						'Could not find default stock count for game ' .. (game or '')
					)
				end
				if remainingLife > startingLife then
					startingLife = remainingLife
				end
				return Array.map(Array.range(1, startingLife), function(pos)
					return {name = character, status = characterStatus(startingLife, remainingLife, pos, pos == startingLife)}
				end)
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
