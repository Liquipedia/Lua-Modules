---
-- @Liquipedia
-- wiki=criticalops
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MathUtil = require('Module:MathUtil')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local DEFAULT_MODE = 'team'
local SIDE_DEF = 'ct'
local SIDE_ATK = 't'

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = Logic.nilIfEmpty(match.finished) or match.status --[[@as string?]]
	match.status = nil
	local winnerInput = match.winner --[[@as string?]]

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, {})
	end)

	local games = MatchFunctions.extractMaps(match, #opponents)
	match.bestof = MatchGroupInputUtil.getBestOf(nil, games)
	games = MatchFunctions.removeUnsetMaps(games)
	match.links = MatchGroupInputUtil.getLinks(match)

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
		match.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
		match.winner = MatchGroupInputUtil.getWinner(match.status, winnerInput, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.status, match.winner, opponentIndex)
		end)
	end

	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE)
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)

	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end

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

---@param match table
---@param opponentCount integer
---@return table[]
function MatchFunctions.extractMaps(match, opponentCount)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		map.opponents = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map))
			return {score = score, status = status}
		end)

		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
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

---@param map table
---@return table
function MapFunctions.getExtraData(map)
	local extradata = MapFunctions.getSideData(map)

	return Table.merge(extradata, {comment = map.comment})
end

---@param map table
---@return table
function MapFunctions.getSideData(map)
	---@param sideInput string
	---@return boolean
	local isValidSide = function(sideInput)
		return Logic.isNotEmpty(sideInput) and (sideInput == SIDE_DEF or sideInput == SIDE_ATK)
	end

	---@param prefix string
	---@param t1Side string
	---@param t2Side string
	---@return {t1Side: string, t2Side: string, t1Half: integer, t2Half: integer}?
	local getDataFor = function(prefix, t1Side, t2Side)
		local half1 = tonumber(map[prefix .. 't1' .. t1Side])
		local half2 = tonumber(map[prefix .. 't2' .. t2Side])
		if not half1 or not half2 then return end
		return {
			t1Side = t1Side,
			t2Side = t2Side,
			t1Half = half1,
			t2Half = half2,
		}
	end

	---@param prefix string
	---@return {t1Side: string, t2Side: string, t1Half: integer, t2Half: integer}[]?
	local getSideData = function(prefix)
		local t1Side = map[prefix .. 't1firstside']
		if not isValidSide(t1Side) then return end
		local t2Side = t1Side == SIDE_DEF and SIDE_ATK or SIDE_DEF

		return Array.append({},
			getDataFor(prefix, t1Side, t2Side),
			getDataFor(prefix, t2Side, t1Side)
		)
	end

	local sideData = getSideData('') or {}

	Array.extendWith(sideData, Array.mapIndexes(function(overtimeIndex)
		return getSideData('o' .. overtimeIndex)
	end))

	return {
		t1sides = Array.map(sideData, Operator.property('t1Side')),
		t2sides = Array.map(sideData, Operator.property('t2Side')),
		t1halfs = Array.map(sideData, Operator.property('t1Half')),
		t2halfs = Array.map(sideData, Operator.property('t2Half')),
	}
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local sideData = MapFunctions.getSideData(map)
	return function(opponentIndex)
		local partialScores = sideData['t' .. opponentIndex .. 'halfs']
		if Logic.isEmpty(partialScores) then
			return
		end

		return MathUtil.sum(partialScores)
	end
end

return CustomMatchGroupInput
