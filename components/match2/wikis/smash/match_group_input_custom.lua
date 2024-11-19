---
-- @Liquipedia
-- wiki=smash
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterStandardizationData = mw.loadData('Module:CharacterStandardization')
local Json = require('Module:Json')
local Lua = require('Module:Lua')

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
	local function characterAlive(startingLife, remainingLife, pos)
		return startingLife - pos < remainingLife
	end

	-- Input Format is "character,remainingLife,startingLife" per index
	local players = Array.mapIndexes(function(playerIndex)
		return opponent.match2players[playerIndex] or
			(map['o' .. opponentIndex .. 'p' .. playerIndex] and {}) or
			nil
	end)
	local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
		opponent.match2players,
		players,
		function(playerIndex)
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
				if remainingLife > startingLife then
					mw.log('Warning: ' .. (playerIdData.name or playerIndex).. ' has more life remaining than starting.')
					startingLife = remainingLife
				end
				return Array.map(Array.range(1, startingLife), function(pos)
					return {name = character, active = characterAlive(startingLife, remainingLife, pos)}
				end)
			end)
			return {
				characters = characters,
				player = playerIdData.name,
			}
		end
	)
	Array.forEach(unattachedParticipants, function(participant)
		table.insert(participants, participant)
	end)
	return participants
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not map.finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return {
		comment = map.comment,
	}
end

return CustomMatchGroupInput
