---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input/Starcraft/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Streams = Lua.import('Module:Links/Stream')

local StarcraftMatchGroupInput = Lua.import('Module:MatchGroup/Input/Starcraft')
local BaseMatchFunctions = StarcraftMatchGroupInput.MatchFunctions
local BaseMapFunctions = StarcraftMatchGroupInput.MapFunctions

local ADVANCE_BACKGROUND = 'up'
local DEFUALT_BACKGROUND = 'down'
local VALID_BACKGROUNDS = {
	ADVANCE_BACKGROUND,
	DEFUALT_BACKGROUND,
	'stayup',
	'staydown',
	'stay',
}
local MODE_FFA = 'FFA'
local TBD = 'TBD'

local StarcraftFfaMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function StarcraftFfaMatchGroupInput.processMatch(match, options)
	Table.mergeInto(match, BaseMatchFunctions.readDate(match.date))

	match.stream = Streams.processStreams(match)
	match.vod = Logic.nilIfEmpty(match.vod)
	match.links = BaseMatchFunctions.getLinks(match)

	MatchGroupInputUtil.getCommonTournamentVars(match)

	local opponents = BaseMatchFunctions.readOpponents(match)

	local games = MatchFunctions.extractMaps(match, opponents)

	local finishedInput = match.finished --[[@as string?]]
	local bestof = tonumber(match.firstto) or tonumber(match.bestof)

	-- need to set this to nil for MatchGroupInputUtil.matchIsFinished usage
	match.bestof = nil
	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)
	match.bestof = bestof
	match.mode = MODE_FFA

	if MatchGroupInputUtil.isNotPlayed(match.winner, finishedInput) then
		match.finished = true
		match.status = 'notplayed' -- according to RFC ;)
		match.resulttype = MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED
		match.scores = {}
		match.statuses = {}
		match.extradata = {ffa = 'true'}
		return match
	end

	match.pbg = MatchFunctions.getPBG(match)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and not Logic.readBool(match.noscore)
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

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(match.winner, finishedInput, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		StarcraftFfaMatchGroupInput._setPlacements(opponents)
		match.winner = StarcraftFfaMatchGroupInput._getWinner(opponents, match.winner, match.resulttype)
	end

	Array.forEach(opponents, function(opponent)
		opponent.extradata = opponent.extradata or {}
		opponent.extradata.bg = MatchFunctions.readBg(opponent.bg)
			or match.pbg[opponent.placement]
			or DEFUALT_BACKGROUND

		-- todo: get rid of the damn alias ...
		if Logic.isEmpty(opponent.advances) and Logic.isNotEmpty(opponent.win) then
			opponent.advances = opponent.win
			mw.ext.TeamLiquidIntegration.add_category('Pages with ffa matches using `|win=` in opponents')
		end

		opponent.extradata.advances = (opponent.score or 0) >= match.bestof
			or opponent.bg == ADVANCE_BACKGROUND
			or Logic.readBool(opponent.advances)
	end)

	match.opponents = opponents
	match.games = games

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end

---@param maps table[]
---@param opponents table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps, opponents)
	return function(opponentIndex)
		local opponent = opponents[opponentIndex]
		local sum = (opponent.extradata.advantage or 0) - (opponent.extradata.penalty or 0)
		Array.forEach(maps, function(map)
			sum = sum + ((map.scores or {})[opponentIndex] or 0)
		end)
		return sum
	end
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local hasScores = not Logic.readBool(match.noscore)
	local maps = {}
	for mapKey, mapInput in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = MapFunctions.readMap(mapInput, #opponents, hasScores)

		map.participants = BaseMapFunctions.getParticipants(mapInput, opponents)

		map.mode = BaseMapFunctions.getMode(mapInput, map.participants, opponents)

		table.insert(maps, map)
		match[mapKey] = nil
	end

	return maps
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	local extradata = {
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
		ffa = 'true',
		noscore = tostring(Logic.readBool(match.noscore)),
		showplacement = tostring(Logic.readBool(match.showplacement)),
	}

	for prefix, vetoMap, vetoIndex in Table.iter.pairsByPrefix(match, 'veto') do
		BaseMatchFunctions.getVeto(extradata, vetoMap, match, prefix, vetoIndex)
	end

	Array.forEach(match.pbg, function(value, key) extradata['pbg' .. key] = value end)

	return extradata
end

---@param match table
---@return table
function MatchFunctions.getPBG(match)
	return Array.mapIndexes(function(pbgIndex)
		return MatchFunctions.readBg(match['pbg' .. pbgIndex])
	end)
end

---@param input string?
---@return string?
function MatchFunctions.readBg(input)
	if Logic.isEmpty(input) then return nil end
	---@cast input -nil

	input = string.lower(input)
	assert(Table.includes(VALID_BACKGROUNDS, input), 'Bad bg/pbg entry "' .. input .. '"')

	return input
end

---@param mapInput table
---@param opponentCount integer
---@param hasScores boolean
---@return table
function MapFunctions.readMap(mapInput, opponentCount, hasScores)
	local mapName = mapInput.map
	if mapName and mapName:upper() ~= TBD then
		mapName = mw.ext.TeamLiquidIntegration.resolve_redirect(mapInput.map)
	elseif mapName then
		mapName = TBD
	end

	local map = {
		map = mapName,
		patch = Variables.varDefault('tournament_patch', ''),
		vod = mapInput.vod,
		extradata = {
			comment = mapInput.comment,
			displayname = mapInput.mapDisplayName,
		}
	}

	if MatchGroupInputUtil.isNotPlayed(mapInput.winner, mapInput.finished) then
		map.finished = true
		map.status = 'notplayed' -- according to RFC ;)
		map.resulttype = MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED
		map.scores = {}
		map.statuses = {}
		return map
	end

	-- todo: get rid of the damn alias ...
	Array.forEach(Array.range(1, opponentCount), function(opponentIndex)
		if not map['score' .. opponentIndex] and map['points' .. opponentIndex] then
			mw.ext.TeamLiquidIntegration.add_category('Pages with ffa matches using `|pointsX=` in maps')
			map['score' .. opponentIndex] = map['points' .. opponentIndex]
		end
	end)

	local opponentsInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
		return MapFunctions.getOpponentInfo(mapInput, opponentIndex, hasScores)
	end)

	map.finished = MapFunctions.isFinished(mapInput, opponentCount, hasScores)
	if map.finished then
		map.resulttype = MatchGroupInputUtil.getResultType(mapInput.winner, mapInput.finished, opponentsInfo)
		map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentsInfo)
		StarcraftFfaMatchGroupInput._setPlacements(opponentsInfo)
		map.winner = StarcraftFfaMatchGroupInput._getWinner(opponentsInfo, mapInput.winner, map.resulttype)
	end

	Array.forEach(opponentsInfo, function(opponentInfo, opponentIndex)
		map.extradata['placement' .. opponentIndex] = opponentInfo.placement
	end)

	return map
end

---@param mapInput table
---@param opponentCount integer
---@param hasScores boolean
---@return boolean
function MapFunctions.isFinished(mapInput, opponentCount, hasScores)
	local finished = Logic.readBoolOrNil(mapInput.finished)
	if finished ~= nil then
		return finished
	end

	return Array.any(Array.range(1, opponentCount), function(opponentIndex)
		return Logic.isNotEmpty(mapInput['placement' .. opponentIndex]) or
			(hasScores and Logic.isNotEmpty(mapInput['score' .. opponentIndex]))
	end)
end

---@param mapInput any
---@param opponentIndex any
---@param hasScores any
---@return {placement: integer?, score: integer?, status: string}
function MapFunctions.getOpponentInfo(mapInput, opponentIndex, hasScores)
	local score, status = MatchGroupInputUtil.computeOpponentScore{
		walkover = mapInput.walkover,
		winner = mapInput.winner,
		opponentIndex = opponentIndex,
		score = mapInput['score' .. opponentIndex],
	}

	return {
		placement = tonumber(mapInput['placement' .. opponentIndex]),
		score = hasScores and score or nil,
		status = status,
	}
end

--- helper fucntions applicable for both map and match

---@param opponents {placement: integer?, score: integer?, status: string}
function StarcraftFfaMatchGroupInput._setPlacements(opponents)
	if Array.all(opponents, function(opponent)
		return Logic.isNotEmpty(opponent.placement)
	end) then return end

	---@param status string
	---@return string
	local toPrepareStatus = function(status)
		if status == MatchGroupInputUtil.STATUS.DEFAULT_WIN or status == MatchGroupInputUtil.STATUS.SCORE then
			return status
		end
		return MatchGroupInputUtil.STATUS.DEFAULT_LOSS
	end

	local lastScore, lastStatus

	---@param status string
	---@param score integer?
	---@return boolean
	local isNewPlacement = function(status, score)
		if status ~= lastStatus then
			return true
		elseif status == MatchGroupInputUtil.STATUS.SCORE and score ~= lastScore then
			return true
		end
		return false
	end

	local lastPlacement = 0
	local skippedPlacements = 1
	for _, opponent in Table.iter.spairs(opponents, StarcraftFfaMatchGroupInput._placementSortFunction) do
		local currentStatus = toPrepareStatus(opponent.status)
		local currentScore = opponent.score or 0
		if isNewPlacement(currentStatus, currentScore) then
			lastPlacement = lastPlacement + skippedPlacements
			skippedPlacements = 0
			lastScore = currentScore
			lastStatus = currentStatus
		end
		opponent.placement = opponent.placement or lastPlacement
		skippedPlacements = skippedPlacements + 1
	end
end

---@param opponents {placement: integer?, score: integer?, status: string}
---@param winnerInput integer|string|nil
---@param resultType string?
---@return integer?
function StarcraftFfaMatchGroupInput._getWinner(opponents, winnerInput, resultType)
	if Logic.isNumeric(winnerInput) then
		return tonumber(winnerInput)
	elseif resultType == MatchGroupInputUtil.RESULT_TYPE.DRAW then
		return MatchGroupInputUtil.WINNER_DRAW
	end

	local placements = Array.map(opponents, Operator.property('placement'))
	local bestPlace = Array.min(placements)

	local calculatedWinner = Array.indexOf(placements, FnUtil.curry(Operator.eq, bestPlace))

	return calculatedWinner ~= 0 and calculatedWinner or nil
end

---@param opponents {placement: integer?, score: integer?, status: string}[]
---@param index1 integer
---@param index2 integer
---@return boolean
function StarcraftFfaMatchGroupInput._placementSortFunction(opponents, index1, index2)
	local opponent1 = opponents[index1]
	local opponent2 = opponents[index2]

	if opponent1.status == MatchGroupInputUtil.STATUS_INPUTS.DEFAULT_WIN then
		return true
	elseif Table.includes(MatchGroupInputUtil.STATUS_INPUTS, opponent1.status) then
		return false
	end

	return (opponent1.score or -1) > (opponent2.score or -1)
end

return StarcraftFfaMatchGroupInput
