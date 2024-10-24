---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Input/Starcraft/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
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
local ASSUME_FINISHED_AFTER = MatchGroupInputUtil.ASSUME_FINISHED_AFTER
local NOW = os.time()

local StarcraftFfaMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function StarcraftFfaMatchGroupInput.processMatch(match, options)
	Table.mergeInto(match, BaseMatchFunctions.readDate(match.date))

	match.links = MatchGroupInputUtil.getLinks(match)
	match.stream = Streams.processStreams(match)

	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	local opponents = BaseMatchFunctions.readOpponents(match)

	local games = MatchFunctions.extractMaps(match, opponents)

	local finishedInput = match.finished --[[@as string?]]
	match.bestof = tonumber(match.firstto) or tonumber(match.bestof)

	match.finished = MatchFunctions.isFinished(match, opponents)
	match.mode = MODE_FFA

	if MatchGroupInputUtil.isNotPlayed(match.winner, finishedInput) then
		match.finished = true
		match.resulttype = MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED
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

	Array.forEach(opponents, function(opponent)
		opponent.placement = tonumber(opponent.placement)
	end)

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(match.winner, finishedInput, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		StarcraftFfaMatchGroupInput._setPlacements(opponents)
		match.winner = StarcraftFfaMatchGroupInput._getWinner(opponents, match.winner, match.resulttype)
	end

	Array.forEach(opponents, function(opponent)
		opponent.extradata = opponent.extradata or {}
		opponent.extradata.noscore = Logic.readBool(match.noscore)
		opponent.extradata.bg = MatchFunctions.readBg(opponent.bg)
			or match.pbg[opponent.placement]
			or DEFUALT_BACKGROUND

		opponent.extradata.advances = Logic.readBool(opponent.advances)
			or (match.bestof and (opponent.score or 0) >= match.bestof)
			or opponent.extradata.bg == ADVANCE_BACKGROUND
			or opponent.placement == 1
	end)

	match.opponents = opponents
	match.games = games

	match.extradata = MatchFunctions.getExtraData(match)

	return match
end
---@param match table
---@param opponents {score: integer?}[]
---@return boolean
function MatchFunctions.isFinished(match, opponents)
	if MatchGroupInputUtil.isNotPlayed(match.winner, match.finished) then
		return true
	end

	local finished = Logic.readBoolOrNil(match.finished)
	if finished ~= nil then
		return finished
	end

	-- If a winner has been set
	if Logic.isNotEmpty(match.winner) then
		return true
	end

	-- If enough time has passed since match started, it should be marked as finished
	local threshold = match.dateexact and ASSUME_FINISHED_AFTER.EXACT or ASSUME_FINISHED_AFTER.ESTIMATE
	if match.timestamp ~= DateExt.defaultTimestamp and (match.timestamp + threshold) < NOW then
		return true
	end

	return MatchFunctions.placementHasBeenSet(opponents)
end

---@param opponents table[]
---@return boolean
function MatchFunctions.placementHasBeenSet(opponents)
	return Array.any(opponents, function(opponent) return Logic.isNumeric(opponent.placement) end)
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
		showplacement = Logic.readBoolOrNil(match.showplacement),
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
	local advanceCount = tonumber(match.advancecount) or 0

	return Array.mapIndexes(function(pbgIndex)
		return MatchFunctions.readBg(match['pbg' .. pbgIndex])
			or (pbgIndex <= advanceCount and ADVANCE_BACKGROUND)
			or nil
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
		map.resulttype = MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED
		map.scores = {}
		map.statuses = {}
		return map
	end

	local opponentsInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
		return MapFunctions.getOpponentInfo(mapInput, opponentIndex, hasScores)
	end)

	map.scores = Array.map(opponentsInfo, Operator.property('score'))

	map.finished = MapFunctions.isFinished(mapInput, opponentCount, hasScores)
	if map.finished then
		map.resulttype = MatchGroupInputUtil.getResultType(mapInput.winner, mapInput.finished, opponentsInfo)
		map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentsInfo)
		StarcraftFfaMatchGroupInput._setPlacements(opponentsInfo, not hasScores)
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
---@param noScores boolean?
function StarcraftFfaMatchGroupInput._setPlacements(opponents, noScores)
	if noScores then return end

	if Array.all(opponents, function(opponent)
		return Logic.isNotEmpty(opponent.placement)
	end) then return end

	---@param status string
	---@return string
	local toSortStatus = function(status)
		if status == MatchGroupInputUtil.STATUS.DEFAULT_WIN or status == MatchGroupInputUtil.STATUS.SCORE or not status then
			return status
		end
		return MatchGroupInputUtil.STATUS.DEFAULT_LOSS
	end

	local cache = {}

	---@param status string
	---@param score integer?
	---@param manualPlacement integer?
	---@return boolean
	local isNewPlacement = function(status, score, manualPlacement)
		if manualPlacement then
			return true
		elseif cache.manualPlacement and not manualPlacement then
			return true
		elseif status ~= cache.status then
			return true
		elseif status == MatchGroupInputUtil.STATUS.SCORE and score ~= cache.score then
			return true
		end
		return false
	end

	cache.placement = 1
	cache.skipped = 0
	for _, opponent in Table.iter.spairs(opponents, StarcraftFfaMatchGroupInput._placementSortFunction) do
		local currentStatus = toSortStatus(opponent.status)
		local currentScore = opponent.score or 0
		if isNewPlacement(currentStatus, currentScore, opponent.placement) then
			cache.manualPlacement = opponent.placement
			cache.placement = opponent.placement or (cache.placement + cache.skipped)
			cache.skipped = 0
			cache.score = currentScore
			cache.status = currentStatus
		end
		opponent.placement = cache.placement
		cache.skipped = cache.skipped + 1
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

	if (opponent1.score or -1) ~= (opponent2.score or -1) then
		return (opponent1.score or -1) > (opponent2.score or -1)
	end

	if opponent1.placement and opponent2.placement then
		return opponent1.placement < opponent2.placement
	elseif opponent1.placement and not opponent2.placement then
		return true
	elseif opponent2.placement and not opponent1.placement then
		return false
	end

	return index1 < index2
end

return StarcraftFfaMatchGroupInput
