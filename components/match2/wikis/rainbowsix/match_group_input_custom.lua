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
local DUMMY_MAP = 'null' -- Is set in Template:Map when |map= is empty.
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
	local games = MatchFunctions.extractMaps(input, #opponents)
	local bestof = MatchGroupInputUtil.getBestOf(nil, games)
	games = MatchFunctions.removeUnsetMaps(games)

	local dateDetails = MatchGroupInputUtil.readDate(input.date)
	local tournamentContext = MatchGroupInputUtil.getTournamentContext(input)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(TODO, games)
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

	local match = Table.merge({
		opponents = opponents,
		games = games,
		finished = MatchGroupInputUtil.matchIsFinished(input, opponents),
		vod = input.vod,
		bestof = bestof,
		extradata = MatchFunctions.getExtraData(input),
		links = MatchFunctions.getLinks(input),
		stream = Streams.processStreams(input),
		mode = Logic.emptyOr(input.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE),
	}, dateDetails, tournamentContext)

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(input.winner, input.finished, match.opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, match.opponents)
		match.winner = MatchGroupInputUtil.getWinner(input.resulttype, input.winner, match.opponents)
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
---@param opponentCount integer
---@return table[]
function MatchFunctions.extractMaps(matchInput, opponentCount)
	local maps = {}

	for _, input in Table.iter.pairsByPrefix(matchInput, 'map', {requireIndex = true}) do
		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = input.walkover,
				winner = input.winner,
				opponentIndex = opponentIndex,
				score = input['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(input))
			return {score = score, status = status}
		end)

		local map = {
			vod = input.vod,
			extradata = MapFunctions.getExtraData(input, opponentCount),
			finished = MatchGroupInputUtil.mapIsFinished(input),
			scores = Array.map(opponentInfo, Operator.property('score'))
		}

		if map.finished then
			map.resulttype = MatchGroupInputUtil.getResultType(input.winner, input.finished, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, input.winner, opponentInfo)
		end

		table.insert(maps, input)
	end

	return maps
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
function MatchFunctions.getLinks(match)
	return {
		stats = match.stats,
		siegegg = match.siegegg and 'https://siege.gg/matches/' .. match.siegegg or nil,
		opl = match.opl and 'https://www.opleague.eu/match/' .. match.opl or nil,
		esl = match.esl and 'https://play.eslgaming.com/match/' .. match.esl or nil,
		faceit = match.faceit and 'https://www.faceit.com/en/rainbow_6/room/' .. match.faceit or nil,
		lpl = match.lpl and 'https://old.letsplay.live/match/' .. match.lpl or nil,
		r6esports = match.r6esports
			and 'https://www.ubisoft.com/en-us/esports/rainbow-six/siege/match/' .. match.r6esports or nil,
		challengermode = match.challengermode and 'https://www.challengermode.com/games/' .. match.challengermode or nil,
		ebattle = match.ebattle and 'https://www.ebattle.gg/turnier/match/' .. match.ebattle or nil,
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
