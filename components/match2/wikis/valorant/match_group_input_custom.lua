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

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')

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

	Table.mergeInto(match, MatchGroupInput.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInput.readOpponent(match, opponentIndex, {})
	end)
	local games = CustomMatchGroupInput.extractMaps(match, #opponents)
	match.bestof = MatchGroupInput.getBestOf(nil, games)
	games = MatchFunctions.removeUnsetMaps(games)

	local autoScoreFunction = MatchGroupInput.canUseAutoScore(match, opponents)
		and MatchFunctions.calculateMatchScore(games, match.bestof)
		or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInput.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInput.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInput.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInput.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInput.getWinner(match.resulttype, winnerInput, opponents)
		MatchGroupInput.setPlacement(opponents, match.winner, 1, 2)
	end

	MatchFunctions.getTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match)

	match.extradata = MatchFunctions.getExtraData(match)

	match.games = games
	match.opponents = opponents

	return match
end


---@param match table
---@param opponentCount integer
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponentCount)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = MapFunctions.getExtraData(map, opponentCount)
		map.finished = MatchGroupInput.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInput.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInput.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInput.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInput.getWinner(map.resulttype, winnerInput, opponentInfo)
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

-- Calculate the match scores based on the map results.
-- If it's a Best of 1, we'll take the exact score of that map
-- If it's not a Best of 1, we should count the map wins
---@param maps table[]
---@param bestOf integer
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps, bestOf)
	return function(opponentIndex)
		if bestOf == 1 then
			if not maps[1] or not maps[1].scores then
				return
			end
			return maps[1].scores[opponentIndex]
		end
		return MatchGroupInput.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.patch = Logic.emptyOr(match.patch, Variables.varDefault('patch'))

	return MatchGroupInput.getCommonTournamentVars(match)
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
		mapveto = MatchGroupInput.getMapVeto(match),
		mvp = MatchGroupInput.readMvp(match),
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
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
---@return table
function MapFunctions.getExtraData(map, participants)
	local extraData = {
		comment = map.comment,
		t1firstside = map.t1firstside,
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
	}

	for key, participant in pairs(participants) do
		local opponentIdx, playerIdx = unpack(mw.text.split(key, '_', true))
		extraData['t' .. opponentIdx .. 'p' .. playerIdx] = participant.player
		extraData['t' .. opponentIdx .. 'p' .. playerIdx .. 'agent'] = participant.agent
	end

	return extraData
end

---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getParticipantsData(map, opponentCount)
	local participants = {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, AgentNames)

	for opponentIdx = 1, opponentCount do
		Array.forEach(Array.mapIndexes(function(playerIdx)
			local stats = map['t' .. opponentIdx .. 'p' .. playerIdx]

			if not stats then
				return
			end

			return Json.parseIfString(stats)
		end), function(stats, playerIdx)
			---@cast stats -nil
			local participant = participants[opponentIdx .. '_' .. playerIdx] or {}

			local function addProperty(key, value)
				participant[key] = Logic.isNotEmpty(stats[key]) and stats[key] or value
			end

			addProperty('kills', participant.kills)
			addProperty('deaths', participant.deaths)
			addProperty('assists', participant.assists)
			addProperty('agent', participant.agent)
			addProperty('acs', participant.averagecombatscore)
			addProperty('player', participant.player)

			participant.agent = getCharacterName(participant.agent)

			participants[opponentIdx .. '_' .. playerIdx] = participant
		end)
	end

	return participants
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	return function(opponentIndex)
		if not map['t'.. opponentIndex ..'atk'] and map['t'.. opponentIndex ..'def'] then
			return
		end
		return (tonumber(map['t'.. opponentIndex ..'atk']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'def']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'otatk']) or 0)
			+ (tonumber(map['t'.. opponentIndex ..'otdef']) or 0)
	end
end

return CustomMatchGroupInput
