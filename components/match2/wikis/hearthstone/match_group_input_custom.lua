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
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local Streams = Lua.import('Module:Links/Stream')

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	pagifyPlayerNames = true,
}
local TBD = 'TBD'

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)

	local games = MatchFunctions.extractMaps(match, opponents)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInputUtil.getWinner(match.resulttype, winnerInput, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.resulttype, match.winner, opponentIndex)
		end)
	end

	match.mode = Variables.varDefault('tournament_mode', 'singles')
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)

	match.games = games
	match.opponents = opponents

	return match
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
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local maps = {}
	for mapKey, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		if String.isNotEmpty(map.map) and string.upper(map.map) ~= TBD then
			map.map = mw.ext.TeamLiquidIntegration.resolve_redirect(map.map)
		end

		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, #opponents), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map.winner, map.finished))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		map.extradata = MapFunctions.getExtradata(map, opponents)

		map.participants = MapFunctions.getParticipants(map, opponents)

		table.insert(maps, map)
		match[mapKey] = nil
	end

	return maps
end

---@param mapInput table
---@param opponents table[]
---@return table
function MapFunctions.getExtradata(mapInput, opponents)
	local extradata = {comment = mapInput.comment}

	Array.forEach(opponents, function(opponent, opponentIndex)
		local prefix = 'o' .. opponentIndex .. 'p'
		local chars = Array.mapIndexes(function(charIndex)
			return Logic.nilIfEmpty(mapInput[prefix .. charIndex .. 'char']) or Logic.nilIfEmpty(mapInput[prefix .. charIndex])
		end)
		Array.forEach(chars, function(char, charIndex)
			extradata[prefix .. charIndex] = MapFunctions.readCharacter(char)
		end)
	end)

	return extradata
end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
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
