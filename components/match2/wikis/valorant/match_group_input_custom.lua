---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local AgentNames = require('Module:AgentNames')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local DUMMY_MAP = 'null' -- Is set in Template:Map when |map= is empty.
local DEFAULT_MODE = 'team'

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, {})
	end)
	local games = CustomMatchGroupInput.extractMaps(match, opponents)
	match.bestof = MatchGroupInputUtil.getBestOf(nil, games)
	games = MatchFunctions.removeUnsetMaps(games)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games, match.bestof)
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
		MatchGroupInputUtil.setPlacement(opponents, match.winner, 1, 2, match.resulttype)
	end

	MatchFunctions.getTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match)

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end


---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.opponents = MapFunctions.getParticipants(map, opponents)
		-- Match/Subobjects:luaGetMap sets a empty table as default value for participants.
		-- Once subobjects have been refactored away this can be removed.
		map.participants = nil
		map.extradata = MapFunctions.getExtraData(map, map.opponents)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(opponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

CustomMatchGroupInput.processMap = FnUtil.identity

--
-- match related functions
--

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored
-- The keepMap function will check if a map should be kept
---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, MapFunctions.keepMap)
end

---@param maps table[]
---@param bestOf integer
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps, bestOf)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.patch = Logic.emptyOr(match.patch, Variables.varDefault('patch'))

	return MatchGroupInputUtil.getCommonTournamentVars(match)
end

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	return {
		vlr = match.vlr and 'https://vlr.gg/' .. match.vlr or nil,
	}
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		mvp = MatchGroupInputUtil.readMvp(match),
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end

--
-- map related functions
--
-- Check if a map should be discarded due to being redundant
-- DUMMY_MAP_NAME needs the match the default value in Template:Map
---@param map table
---@return boolean
function MapFunctions.keepMap(map)
	return map.map ~= DUMMY_MAP
end

---@param map table
---@param participants {players: {player: string?, agent: string?}[]}[]
---@return table<string, any>
function MapFunctions.getExtraData(map, participants)
	---@type table<string, any>
	local extraData = {
		comment = map.comment,
		t1firstside = map.t1firstside,
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
	}

	for opponentIdx, opponent in ipairs(participants) do
		for playerIdx, player in pairs(opponent.players) do
			extraData['t' .. opponentIdx .. 'p' .. playerIdx] = player.player
			extraData['t' .. opponentIdx .. 'p' .. playerIdx .. 'agent'] = player.agent
		end
	end

	return extraData
end

---@param map table
---@param opponents MGIParsedOpponent[]
---@return {players: table[]}[]
function MapFunctions.getParticipants(map, opponents)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, AgentNames)

	return Array.map(opponents, function(opponent, opponentIndex)
		local players = Array.mapIndexes(function(playerIndex)
			return opponent.match2players[playerIndex] or
				(map['t' .. opponentIndex .. 'p' .. playerIndex] and {}) or
				nil
		end)
		local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
			opponent.match2players,
			players,
			function(playerIndex)
				local data = Json.parseIfString(map['t' .. opponentIndex .. 'p' .. playerIndex])
				return data and {name = data.player} or nil
			end,
			function(playerIndex, playerIdData, playerInputData)
				local stats = Json.parseIfString(map['t'.. opponentIndex .. 'p' .. playerIndex]) or {}
				return {
					kills = stats.kills,
					deaths = stats.deaths,
					assists = stats.assists,
					acs = stats.acs,
					player = playerIdData.name or playerInputData.name,
					agent = getCharacterName(stats.agent),
				}
			end
		)
		Array.forEach(unattachedParticipants, function(participant)
			table.insert(participants, participant)
		end)
		return {players = participants}
	end)
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	return function(opponentIndex)
		if not map['t'.. opponentIndex ..'atk'] and not map['t'.. opponentIndex ..'def'] then
			return
		end
		return (tonumber(map['t'.. opponentIndex ..'atk']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'def']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'otatk']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'otdef']) or 0)
	end
end

return CustomMatchGroupInput
