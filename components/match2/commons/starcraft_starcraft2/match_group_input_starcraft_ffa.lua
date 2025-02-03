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

local StarcraftMatchGroupInput = Lua.import('Module:MatchGroup/Input/Starcraft')
local BaseMatchFunctions = StarcraftMatchGroupInput.MatchFunctions
local BaseMapFunctions = StarcraftMatchGroupInput.MapFunctions

local MODE_FFA = 'FFA'
local TBD = 'TBD'
local ASSUME_FINISHED_AFTER = MatchGroupInputUtil.ASSUME_FINISHED_AFTER
local NOW = os.time()

local StarcraftFfaMatchGroupInput = {}
local MatchFunctions = {
	OPPONENT_CONFIG = {
		resolveRedirect = true,
		pagifyTeamNames = true,
	},
	readDate = BaseMatchFunctions.readDate,
	getMatchWinner = StarcraftFfaMatchGroupInput._getWinner,
}
local MapFunctions = {}

---@param matchInput table
---@param options table?
---@return table
function StarcraftFfaMatchGroupInput.processMatch(matchInput, options)
	matchInput.bestof = tonumber(matchInput.firstto) or tonumber(matchInput.bestof)

	local match = MatchGroupInputUtil.standardProcessFfaMatch(matchInput, MatchFunctions)

	Array.forEach(match.opponents, function(opponent)
		opponent.extradata.advances = Logic.readBool(opponent.advances)
			or (matchInput.bestof and (opponent.score or 0) >= matchInput.bestof)
			or opponent.placement == 1
	end)

	return match
end

---@param match table
---@param numberOfOpponents integer
---@return table
function MatchFunctions.parseSettings(match, numberOfOpponents)
	local settings = MatchGroupInputUtil.parseSettings(match, numberOfOpponents)
	Table.mergeInto(settings.settings, {
		noscore = Logic.readBool(match.noscore),
		showGameDetails = false,
	})
	return settings
end

---@param opponent table
---@param opponentIndex integer
---@param match table
function MatchFunctions.adjustOpponent(opponent, opponentIndex, match)
	BaseMatchFunctions.adjustOpponent(opponent, opponentIndex)
	-- set score to 0 for all opponents if it is a match without scores
	if Logic.readBool(match.noscore) then
		opponent.score = 0
	end
end

---@param opponents table[]
---@param games table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(opponents, games)
	return function(opponentIndex)
		local opponent = opponents[opponentIndex]
		local sum = (opponent.extradata.advantage or 0) - (opponent.extradata.penalty or 0)
		Array.forEach(games, function(game)
			local scores = Array.map(game.opponents, Operator.property('score'))
			sum = sum + ((scores or {})[opponentIndex] or 0)
		end)
		return sum
	end
end

---@param opponents table[]
---@return string
function MatchFunctions.getMode(opponents)
	return MODE_FFA
end

---@param match table
---@param opponents {score: integer?}[]
---@return boolean
function MatchFunctions.matchIsFinished(match, opponents)
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

---@param match table
---@param games table[]
---@param opponents table[]
---@param settings table
---@return table
function MatchFunctions.getExtraData(match, games, opponents, settings)
	local extradata = {
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
		ffa = 'true',
		showplacement = Logic.readBoolOrNil(match.showplacement),
		placementinfo = settings.placementInfo,
		settings = settings.settings,
	}

	for prefix, vetoMap, vetoIndex in Table.iter.pairsByPrefix(match, 'veto') do
		BaseMatchFunctions.getVeto(extradata, vetoMap, match, prefix, vetoIndex)
	end

	return extradata
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local hasScores = not Logic.readBool(match.noscore)
	local maps = {}
	for mapKey, mapInput in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = MapFunctions.readMap(match, mapInput, #opponents, hasScores)

		Array.forEach(map.opponents, function(opponent, opponentIndex)
			opponent.players = BaseMapFunctions.getPlayersOfMapOpponent(map, opponents[opponentIndex], opponentIndex)
		end)

		map.mode = BaseMapFunctions.getMapMode(match, map, opponents)

		table.insert(maps, map)
		match[mapKey] = nil
	end

	return maps
end

---@param match table
---@param mapInput table
---@param opponentCount integer
---@param hasScores boolean
---@return table
function MapFunctions.readMap(match, mapInput, opponentCount, hasScores)
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
			settings = {noscore = not hasScores},
		}
	}

	Table.mergeInto(map, MatchGroupInputUtil.readDate(mapInput.date or match.date))

	if MatchGroupInputUtil.isNotPlayed(mapInput.winner, mapInput.finished) then
		map.finished = true
		map.status = MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED
		map.scores = {}
		return map
	end

	map.opponents = Array.map(Array.range(1, opponentCount), function(opponentIndex)
		return MapFunctions.getOpponentInfo(mapInput, opponentIndex)
	end)

	map.scores = Array.map(map.opponents, Operator.property('score'))

	map.finished = MapFunctions.isFinished(mapInput, opponentCount, hasScores)
	if map.finished then
		map.status = MatchGroupInputUtil.getMatchStatus(mapInput.winner, mapInput.finished)
		local placementOfOpponents = MatchGroupInputUtil.calculatePlacementOfOpponents(map.opponents)
		Array.forEach(map.opponents, function(opponent, opponentIndex)
			opponent.placement = placementOfOpponents[opponentIndex]
		end)
		map.winner = StarcraftFfaMatchGroupInput._getWinner(map.status, mapInput.winner, map.opponents)
	end

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

---@param mapInput table
---@param opponentIndex integer
---@return {placement: integer?, score: integer?, status: string}
function MapFunctions.getOpponentInfo(mapInput, opponentIndex)
	local score, status = MatchGroupInputUtil.computeOpponentScore{
		walkover = mapInput.walkover,
		winner = mapInput.winner,
		opponentIndex = opponentIndex,
		score = mapInput['score' .. opponentIndex],
	}

	return {
		placement = tonumber(mapInput['placement' .. opponentIndex]),
		score = score,
		status = status,
	}
end

---@param status string
---@param winnerInput integer|string|nil
---@param opponents {placement: integer?, score: integer?, status: string}[]
---@return integer?
function StarcraftFfaMatchGroupInput._getWinner(status, winnerInput, opponents)
	if status == MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED then
		return nil
	elseif Logic.isNumeric(winnerInput) then
		return tonumber(winnerInput)
	elseif MatchGroupInputUtil.isDraw(opponents, winnerInput) then
		return MatchGroupInputUtil.WINNER_DRAW
	end

	local placements = Array.map(opponents, Operator.property('placement'))
	local bestPlace = Array.min(placements)

	local calculatedWinner = Array.indexOf(placements, FnUtil.curry(Operator.eq, bestPlace))

	return calculatedWinner ~= 0 and calculatedWinner or nil
end

return StarcraftFfaMatchGroupInput
