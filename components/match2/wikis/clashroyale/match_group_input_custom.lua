---
-- @Liquipedia
-- wiki=clashroyale
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
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent


local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

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
	local maps = {}
	local subGroup = 0
	for mapKey, mapInput, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if Table.isEmpty(mapInput) then
			break
		end
		local map
		map, subGroup = MapFunctions.readMap(mapInput, mapIndex, subGroup, opponents)

		map.extradata = MapFunctions.getExtraData(mapInput, map.opponents)

		map.vod = Logic.emptyOr(mapInput.vod, match['vodgame' .. mapIndex])

		table.insert(maps, map)
		match[mapKey] = nil
	end

	return maps
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

---@param mapInput table
---@param mapIndex integer
---@param subGroup integer
---@param opponents table[]
---@return table
---@return integer
function MapFunctions.readMap(mapInput, mapIndex, subGroup, opponents)
	subGroup = tonumber(mapInput.subgroup) or (subGroup + 1)

	local map = {
		subgroup = subGroup,
	}

	map.finished = MatchGroupInputUtil.mapIsFinished(mapInput)
	map.opponents = Array.map(opponents, function(opponent, opponentIndex)
		local score, status = MatchGroupInputUtil.computeOpponentScore({
			walkover = mapInput.walkover,
			winner = mapInput.winner,
			opponentIndex = opponentIndex,
			score = mapInput['score' .. opponentIndex],
		}, MapFunctions.calculateMapScore(mapInput, map.finished))
		local players = MapFunctions.getPlayersOfMapOpponent(mapInput, opponent, opponentIndex)
		return {score = score, status = status, players = players}
	end)

	map.scores = Array.map(map.opponents, Operator.property('score'))

	if map.finished then
		map.status = MatchGroupInputUtil.getMatchStatus(mapInput.winner, mapInput.finished)
		map.winner = MatchGroupInputUtil.getWinner(map.status, mapInput.winner, map.opponents)
	end

	return map, subGroup
end

---@param mapInput table
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(mapInput, finished)
	local winner = tonumber(mapInput.winner)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
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

	local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
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

	Array.forEach(unattachedParticipants, function(participant)
		table.insert(opponent.match2players, {
			name = participant.player,
			displayname = participant.player,
		})
		participants[#opponent.match2players] = participant
	end)

	return participants
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

---@param mapInput table
---@param mapOpponents {players: {player: string, played: boolean, cards: table}[]}[]
---@return table
function MapFunctions.getExtraData(mapInput, mapOpponents)
	local extradata = {
		comment = mapInput.comment,
	}

	return Table.merge(extradata, MapFunctions.getCardsExtradata(mapOpponents))
end

--- additionally store cards info in extradata so we can condition on them
---@param mapOpponents {players: {player: string, played: boolean, cards: table}[]}[]
---@return table
function MapFunctions.getCardsExtradata(mapOpponents)
	local extradata = {}
	for opponentIndex, opponent in ipairs(mapOpponents) do
		for playerIndex, player in pairs(opponent.players) do
			local prefix = 't' .. opponentIndex .. 'p' .. playerIndex
			extradata[prefix .. 'tower'] = player.cards.tower
			-- participant.cards is an array plus the tower value ....
			for cardIndex, card in ipairs(player.cards) do
				extradata[prefix .. 'c' .. cardIndex] = card
			end
		end
	end
	return extradata
end

---@param input string
---@return table
function CustomMatchGroupInput._readCards(input)
	local cleanCard = FnUtil.curry(MatchGroupInputUtil.getCharacterName, CardNames)

	return Table.mapValues(Json.parseIfString(input) or {}, cleanCard)
end

return CustomMatchGroupInput
