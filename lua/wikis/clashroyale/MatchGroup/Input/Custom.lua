---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CardNames = mw.loadData('Module:CardNames')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent


local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {
	ADD_SUB_GROUP = true,
	BREAK_ON_EMPTY = true,
}

MatchFunctions.DEFAULT_MODE = 'solo'
MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
}

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
---@param opponents table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps, opponents)
	return function(opponentIndex)
		local calculatedScore = MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
		if not calculatedScore then return end
		local opponent = opponents[opponentIndex]
		return calculatedScore + (opponent.extradata.advantage or 0) - (opponent.extradata.penalty or 0)
	end
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput) or tonumber(Variables.varDefault('match_bestof'))

	if bestof then
		Variables.varDefine('match_bestof', bestof)
	end

	return bestof
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	local extradata = {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}

	local prefix = 'subgroup%d+'
	Table.mergeInto(extradata, Table.filterByKey(match, function(key) return key:match(prefix .. 'header') end))
	Table.mergeInto(extradata, Table.filterByKey(match, function(key) return key:match(prefix .. 'iskoth') end))

	return extradata
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	return function(opponentIndex)
		-- to be able to legacy convert old brackets/matchlists need to add manual score input per map ...
		if Logic.isNumeric(map['score' .. opponentIndex]) then
			return tonumber(map['score' .. opponentIndex])
		end

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
---@return {player: string, played: boolean, cards: table}[]
function MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex)
	local players = Array.mapIndexes(function(playerIndex)
		return Logic.nilIfEmpty(mapInput['t' .. opponentIndex .. 'p' .. playerIndex])
	end)

	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			local prefix = 't' .. opponentIndex .. 'p' .. playerIndex
			return {
				name = mapInput[prefix],
				link = Logic.nilIfEmpty(mapInput[prefix .. 'link']) or Variables.varDefault(mapInput[prefix] .. '_page'),
			}
		end,
		function(playerIndex, playerIdData, playerInputData)
			local prefix = 'o' .. opponentIndex .. 'p' .. playerIndex
			return {
				played = true,
				player = playerIdData.name or playerInputData.link,
				cards = CustomMatchGroupInput._readCards(mapInput[prefix .. 'c']),
			}
		end
	)
end

---@param mapInput table
---@param opponent table
---@param opponentIndex integer
---@return {player: string, played: boolean, cards: table}[]
function MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	local prefix = 't' .. opponentIndex .. 'p'

	return Array.map(players, function(player, playerIndex)
		return {
			played = true,
			player = player.name,
			cards = CustomMatchGroupInput._readCards(mapInput[prefix .. playerIndex .. 'c']),
		}
	end)
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return MapFunctions.getCardsExtradata(map.opponents)
end

--- additionally store cards info in extradata so we can condition on them
---@param mapOpponents {players: {player: string, played: boolean, cards: table}[]}[]
---@return table
function MapFunctions.getCardsExtradata(mapOpponents)
	local extradata = {}
	Array.forEach(mapOpponents, function(opponent, opponentIndex)
		Array.forEach(Array.filter(opponent.players or {}, Logic.isNotEmpty), function(player, playerIndex)
			local prefix = 't' .. opponentIndex .. 'p' .. playerIndex
			extradata[prefix .. 'tower'] = player.cards.tower
			-- participant.cards is an array plus the tower value ....
			Array.forEach(player.cards, function(card, cardIndex)
				extradata[prefix .. 'c' .. cardIndex] = card
			end)
		end)
	end)

	return extradata
end

---@param input string
---@return table
function CustomMatchGroupInput._readCards(input)
	local cleanCard = FnUtil.curry(MatchGroupInputUtil.getCharacterName, CardNames)

	return Table.mapValues(Json.parseIfString(input) or {}, cleanCard)
end

return CustomMatchGroupInput
