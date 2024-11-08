---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterStandardization = mw.loadData('Module:CharacterStandardization')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}
MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	pagifyPlayerNames = true,
}
local TBD = 'TBD'

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

---@param map table
---@return string?
function MapFunctions.getMapName(map)
	if String.isNotEmpty(map.map) and map.map ~= TBD then
		return mw.ext.TeamLiquidIntegration.resolve_redirect(map.map)
	end
	return map.map
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local extradata = {comment = map.comment}

	Array.forEach(opponents, function(opponent, opponentIndex)
		local prefix = 'o' .. opponentIndex .. 'p'
		local chars = Array.mapIndexes(function(charIndex)
			return Logic.nilIfEmpty(map[prefix .. charIndex .. 'char']) or Logic.nilIfEmpty(map[prefix .. charIndex])
		end)
		Array.forEach(chars, function(char, charIndex)
			extradata[prefix .. charIndex] = MapFunctions.readCharacter(char)
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
		if not winner and not map.finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

---@param mapInput table
---@param opponents table[]
---@return table<string, {character: string?, player: string}>
function MapFunctions.getParticipants(mapInput, opponents)
	local participants = {}
	Array.forEach(opponents, function(opponent, opponentIndex)
		if opponent.type == Opponent.literal then
			return
		elseif opponent.type == Opponent.team then
			Table.mergeInto(participants, MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex))
			return
		end
		Table.mergeInto(participants, MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex))
	end)

	return participants
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return table<string, {character: string?, player: string}>
function MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex)
	local players = Array.mapIndexes(function(playerIndex)
		return Logic.nilIfEmpty(mapInput['o' .. opponentIndex .. 'p' .. playerIndex])
	end)

	local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
		opponent.match2players,
		players,
		function(playerIndex)
			local prefix = 'o' .. opponentIndex .. 'p' .. playerIndex
			return {
				name = mapInput[prefix],
				link = Logic.nilIfEmpty(mapInput[prefix .. 'link']),
			}
		end,
		function(playerIndex, playerIdData, playerInputData)
			local prefix = 'o' .. opponentIndex .. 'p' .. playerIndex
			return {
				player = playerIdData.name or playerInputData.link,
				character = MapFunctions.readCharacter(Logic.nilIfEmpty(mapInput[prefix .. 'char']).character),
			}
		end
	)

	Array.forEach(unattachedParticipants, function(participant)
		table.insert(opponent.match2players, {
			name = participant.player,
			displayname = participant.player,
		})
		participants[#opponent.match2players] = participant
	end)

	return Table.map(participants, MatchGroupInputUtil.prefixPartcipants(opponentIndex))
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return table<string, {character: string?, player: string}>
function MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	local prefix = 'o' .. opponentIndex .. 'p'

	local participants = {}

	Array.forEach(players, function(player, playerIndex)
		participants[opponentIndex .. '_' .. playerIndex] = {
			character = MapFunctions.readCharacter(mapInput[prefix .. playerIndex]),
			player = player.name,
		}
	end)

	return participants
end

---@param input string?
---@return string?
function MapFunctions.readCharacter(input)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, CharacterStandardization)

	return getCharacterName(input)
end

return CustomMatchGroupInput
