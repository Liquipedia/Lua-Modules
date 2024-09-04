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
local Streams = Lua.import('Module:Links/Stream')

local DEFAULT_MODE = 'solo'
local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	pagifyPlayerNames = true,
}
local ROYALE_API_PREFIX = 'https://royaleapi.com/'

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)

	local games = MatchFunctions.extractMaps(match, opponents)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games, opponents)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.bestof = MatchFunctions.getBestOf(match.bestof)

	local winnerInput = match.winner --[[@as string?]]
	local finishedInput = match.finished --[[@as string?]]
	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInputUtil.getWinner(match.resulttype, winnerInput, opponents)
		MatchGroupInputUtil.setPlacement(opponents, match.winner, 1, 2)
	elseif MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput) then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.winner = nil
	end

	MatchFunctions.getTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match)
	match.vod = Logic.nilIfEmpty(match.vod)
	match.extradata = MatchFunctions.getExtraData(match, #games)

	match.games = games
	match.opponents = opponents

	return match
end

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	return {
		royaleapi = match.royaleapi and (ROYALE_API_PREFIX .. match.royaleapi) or nil,
	}
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	return MatchGroupInputUtil.getCommonTournamentVars(match)
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local maps = {}
	local subGroup = 0
	for mapKey, mapInput, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map
		map, subGroup = MapFunctions.readMap(mapInput, mapIndex, subGroup, #opponents)

		map.participants = MapFunctions.getParticipants(mapInput, opponents)
		map.extradata = MapFunctions.getExtraData(mapInput, map.participants)

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
---@param numberOfGames integer
---@return table
function MatchFunctions.getExtraData(match, numberOfGames)
	local extradata = {
		t1bans = MatchFunctions.readBans(match.t1bans),
		t2bans = MatchFunctions.readBans(match.t2bans),
		mvp = MatchGroupInputUtil.readMvp(match),
	}

	local prefix = 'subgroup%d+'
	Table.mergeInto(extradata, Table.filterByKey(match, function(key) return key:match(prefix .. 'header') end))
	Table.mergeInto(extradata, Table.filterByKey(match, function(key) return key:match(prefix .. 'iskoth') end))

	local t1Bans = Table.filterByKey(match, function(key) return key:match(prefix .. 't1bans') end)
	Table.mergeInto(extradata, Table.mapValues(t1Bans, MatchFunctions.readBans))

	local t2Bans = Table.filterByKey(match, function(key) return key:match(prefix .. 't2bans') end)
	Table.mergeInto(extradata, Table.mapValues(t2Bans, MatchFunctions.readBans))

	return extradata
end

---@param bansInput string
---@return table
function MatchFunctions.readBans(bansInput)
	local bans = CustomMatchGroupInput._readCards(bansInput)

	return Logic.nilIfEmpty(bans)
end

---@param mapInput table
---@param mapIndex integer
---@param subGroup integer
---@param opponentCount integer
---@return table
---@return integer
function MapFunctions.readMap(mapInput, mapIndex, subGroup, opponentCount)
	subGroup = tonumber(mapInput.subgroup) or (subGroup + 1)

	local map = {
		map = 'Set ' .. mapIndex, -- CR has no map names, use generic one instead
		subgroup = subGroup,
	}

	map.finished = MatchGroupInputUtil.mapIsFinished(mapInput)
	local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
		local score, status = MatchGroupInputUtil.computeOpponentScore({
			walkover = mapInput.walkover,
			winner = mapInput.winner,
			opponentIndex = opponentIndex,
			score = mapInput['score' .. opponentIndex],
		}, MapFunctions.calculateMapScore(mapInput, map.finished))
		return {score = score, status = status}
	end)

	map.scores = Array.map(opponentInfo, Operator.property('score'))

	if map.finished or MatchGroupInputUtil.isNotPlayed(map.winner, mapInput.finished) then
		map.resulttype = MatchGroupInputUtil.getResultType(mapInput.winner, mapInput.finished, opponentInfo)
		map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
		map.winner = MatchGroupInputUtil.getWinner(map.resulttype, mapInput.winner, opponentInfo)
	end

	return map, subGroup
end

---@param mapInput table
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(mapInput, finished)
	local winner = tonumber(mapInput.winner)
	return function(opponentIndex)
		local manualScore = tonumber(mapInput['score' .. opponentIndex])
		if manualScore then return
			manualScore
		end

		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end

		return winner == opponentIndex and 1 or 0
	end
end

---@param mapInput table
---@param opponents table[]
---@return table<string, {player: string, played: boolean, cards: table}>
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
---@return table<string, {player: string, played: boolean, cards: table}>
function MapFunctions.getTeamParticipants(mapInput, opponent, opponentIndex)
	local players = Array.mapIndexes(function(playerIndex)
		return Logic.nilIfEmpty(mapInput['t' .. opponentIndex .. 'p' .. playerIndex])
	end)

	local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
		opponent.match2players,
		players,
		function(playerIndex)
			local prefix = 'o' .. opponentIndex .. 'p' .. playerIndex
			return {
				name = mapInput[prefix],
				link = Logic.nilIfEmpty(mapInput[prefix .. 'link']) or Variables.varDefault(mapInput[prefix] .. '_page'),
				cards = CustomMatchGroupInput._readCards(mapInput[prefix .. 'c']),
			}
		end,
		function(playerIndex, playerIdData, playerInputData)
			return {
				played = true,
				player = playerIdData.name or playerInputData.link,
				cards = playerInputData.cards,
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
---@return table<string, {player: string, played: boolean, cards: table}>
function MapFunctions.getPartyParticipants(mapInput, opponent, opponentIndex)
	local players = opponent.match2players

	local prefix = 't' .. opponentIndex .. 'p'

	local participants = {}

	Array.forEach(players, function(player, playerIndex)
		participants[opponentIndex .. '_' .. playerIndex] = {
			played = true,
			player = player.name,
			cards = CustomMatchGroupInput._readCards(mapInput[prefix .. playerIndex .. 'c']),
		}
	end)

	return participants
end

---@param mapInput table
---@param participants table<string, {player: string, played: boolean, cards: table}>
---@return table
function MapFunctions.getExtraData(mapInput, participants)
	local extradata = {
		comment = mapInput.comment,
		header = mapInput.header,
	}

	return Table.merge(extradata, MapFunctions.getCardsExtradata(participants))
end

--- additionally store cards info in extradata so we can condition on them
---@param participants table<string, {player: string, played: boolean, cards: table}>
---@return table
function MapFunctions.getCardsExtradata(participants)
	local extradata = {}
	local playerCount = {}
	for participantKey, participant in Table.iter.spairs(participants) do
		local opponentIndex = string.match(participantKey, '^(%d+)_')

		playerCount[opponentIndex] = (playerCount[opponentIndex] or 0) + 1

		local prefix = 't' .. opponentIndex .. 'p' .. playerCount[opponentIndex]
		extradata[prefix .. 'tower'] = participant.cards.tower
		-- participant.cards is an array plus the tower value ....
		for cardIndex, card in ipairs(participant.cards) do
			extradata[prefix .. 'c' .. cardIndex] = card
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