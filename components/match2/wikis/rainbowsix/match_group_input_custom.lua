---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterNames = require('Module:CharacterNames')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local MAX_NUM_BANS = 2
local DEFAULT_MODE = 'team'

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param input table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(input, options)
	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(input, opponentIndex, {})
	end)
	local games = Array.mapIndexes(function (gameIndex)
		return MatchGroupInputUtil.readGame(input, gameIndex, opponents)
	end)
	local bestof = MatchGroupInputUtil.getBestOf(nil, games)
	games = MatchFunctions.removeUnsetMaps(games)

	local dateDetails = MatchGroupInputUtil.readDate(input.date)
	local tournamentContext = MatchGroupInputUtil.getTournamentContext(input)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(dateDetails, games)
		and MatchFunctions.calculateMatchScore(games)
		or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = input.walkover,
			winner = input.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	local finished = MatchGroupInputUtil.matchIsFinished(input.winner, input.finished, opponents, dateDetails, bestof)

	local match = Table.merge({
		opponents = opponents,
		games = games,
		finished = finished,
		vod = input.vod,
		bestof = bestof,
		extradata = MatchFunctions.getExtraData(input),
		links = MatchFunctions.getLinks(input),
		stream = Streams.processStreams(input),
		mode = Logic.emptyOr(input.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE),
	}, dateDetails, tournamentContext)

	if finished then
		match.resulttype = MatchGroupInputUtil.getResultType(input.winner, input.finished, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInputUtil.getWinner(input.resulttype, input.winner, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.resulttype, match.winner, opponentIndex)
		end)
	end

	return match
end

--
-- match related functions
--

---@param matchInput table
---@param mapIndex integer
---@param opponents table[]
---@return table[]?
function MatchFunctions.readMap(matchInput, mapIndex, opponents)
	local input = matchInput['map' .. mapIndex]
	if not input then
		return nil
	end

	local opponentInfo = Array.map(opponents, function(_, opponentIndex)
		local score, status = MatchGroupInputUtil.computeOpponentScore({
			walkover = input.walkover,
			winner = input.winner,
			opponentIndex = opponentIndex,
			score = input['score' .. opponentIndex],
		}, MapFunctions.calculateMapScore(input))
		return {score = score, status = status}
	end)
	local finished = MatchGroupInputUtil.mapIsFinished(input.winner, input.finished)

	local map = {
		vod = input.vod,
		extradata = MapFunctions.getExtraData(input, #opponents),
		finished = finished,
		scores = Array.map(opponentInfo, Operator.property('score'))
	}

	if map.finished then
		map.resulttype = MatchGroupInputUtil.getResultType(input.winner, input.finished, opponentInfo)
		map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
		map.winner = MatchGroupInputUtil.getWinner(map.resulttype, input.winner, opponentInfo)
	end

	return map
end

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored
-- The keepMap function will check if a map should be kept
---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, MapFunctions.keepMap)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
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
---@param map table
---@return boolean
function MapFunctions.keepMap(map)
	return map.map ~= nil
end

-- Parse extradata information, particularally info about halfs and operator bans
---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(map, opponentCount)
	local extradata = {
		comment = map.comment,
		t1firstside = {rt = map.t1firstside, ot = map.t1firstsideot},
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
	}

	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, CharacterNames)
	Array.forEach(Array.range(1, opponentCount), function(opponentIndex)
		extradata['t' .. opponentIndex .. 'bans'] = Array.map(Array.range(1, MAX_NUM_BANS), function(banIndex)
			local ban = map['t' .. opponentIndex .. 'ban' .. banIndex]
			return getCharacterName(ban) or ''
		end)
	end)

	return extradata
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
