---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local DEFAULT_MODE = 'team'

local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.
local OPPONENT_CONFIG = {
	resolveRedirect = true,
	applyUnderScores = true,
	maxNumPlayers = 3,
}

local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	local settings = MatchFunctions.parseSetting(match)

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)

	local games = MatchFunctions.extractMaps(match, opponents, settings.score)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(opponents, games)
		or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.extradata = opponent.extradata or {}
		opponent.extradata.startingpoints = tonumber(opponent.pointmodifier)
		opponent.placement = tonumber(opponent.placement)

		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype =
			MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput)
			and MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED
			or nil
		match.walkover = nil
		match.winner = MatchGroupInputUtil.getWinner(match.resulttype, winnerInput, opponents)
		CustomMatchGroupInput.setPlacements(opponents)
		MatchFunctions.setBgForOpponents(opponents, settings.status)
	end

	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(settings)

	return match
end

CustomMatchGroupInput.processMap = FnUtil.identity

---@param match table
---@param opponents table[]
---@param scoreSettings table
---@return table[]
function MatchFunctions.extractMaps(match, opponents, scoreSettings)
	local maps = {}
	for key, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		if map.map == DUMMY_MAP_NAME then
			map.map = ''
		end

		Table.mergeInto(map, MatchGroupInputUtil.readDate(map.date))
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(opponents, function(matchOpponent)
			local opponentMapInput = Json.parseIfString(matchOpponent['m' .. mapIndex])
			return MapFunctions.makeMapOpponentDetails(opponentMapInput, scoreSettings)
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput)
				and MatchGroupInputUtil.RESULT_TYPE.NOT_PLAYED
				or nil
			map.walkover = nil
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		map.extradata = MapFunctions.getExtraData(map, opponentInfo)

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.scores[opponentIndex] or 0
		end), Operator.add, 0) + (opponents[opponentIndex].startingpoints or 0)
	end
end

---Warning mutates the placement field in each opponent
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.setPlacements(opponents)
	local usedPlacements = Array.map(opponents, function()
		return 0
	end)
	Array.forEach(opponents, function(opponent)
		if opponent.placement then
			usedPlacements[opponent.placement] = usedPlacements[opponent.placement] + 1
		end
	end)
	-- Spread out placements if there are duplicates placements
	-- For example 2 placement at 4 means 5 is also taken and the next available is 6
	Array.forEach(usedPlacements, function(count, placement)
		if count > 1 then
			usedPlacements[placement+1] = usedPlacements[placement + 1] + (count - 1)
			usedPlacements[placement] = 1
		end
	end)

	local function findNextSlot(placement)
		if usedPlacements[placement] == 0 then
			return placement
		end
		return findNextSlot(placement + 1)
	end

	local lastScore
	local lastPlacement = 0
	for _, opp in Table.iter.spairs(opponents, CustomMatchGroupInput.scoreSorter) do
		if not opp.placement then
			local thisPlacement = findNextSlot(lastPlacement)
			usedPlacements[thisPlacement] = 1
			if lastScore and opp.score == lastScore then
				opp.placement = lastPlacement
			else
				opp.placement = thisPlacement
				lastPlacement = opp.placement
				lastScore = opp.score
			end
		end
	end

	return opponents
end

---@param tbl table
---@param key1 string|number
---@param key2 string|number
---@return boolean
function CustomMatchGroupInput.scoreSorter(tbl, key1, key2)
	local value1 = tonumber(tbl[key1].score) or -math.huge
	local value2 = tonumber(tbl[key2].score) or -math.huge
	return value1 > value2
end

--
-- match related functions
--
---@param match table
---@return {score: table, status: table}
function MatchFunctions.parseSetting(match)
	-- Score Settings
	local scoreSettings = {
		kill = tonumber(match.p_kill) or 1,
		matchPointThreadhold = tonumber(match.matchpoint),
		placement = Array.mapIndexes(function(idx)
			return match['opponent' .. idx] and (tonumber(match['p' .. idx]) or 0) or nil
		end)
	}

	-- Up/Down colors
	local statusSettings = Array.flatMap(Array.parseCommaSeparatedString(match.bg, ','), function (status)
		local placements, color = unpack(Array.parseCommaSeparatedString(status, '='))
		local pStart, pEnd = unpack(Array.parseCommaSeparatedString(placements, '-'))
		local pStartNumber = tonumber(pStart) --[[@as integer]]
		local pEndNumber = tonumber(pEnd) or pStartNumber
		return Array.map(Array.range(pStartNumber, pEndNumber), function()
			return color
		end)
	end)

	return {
		score = scoreSettings,
		status = statusSettings,
	}
end

---@param settings table
---@return table
function MatchFunctions.getExtraData(settings)
	return {
		scoring = settings.score,
		status = settings.status,
	}
end

---@param opponents table
---@param statusSettings table
function MatchFunctions.setBgForOpponents(opponents, statusSettings)
	Array.forEach(opponents, function(opponent)
		opponent.extradata.bg = statusSettings[opponent.placement]
	end)
end

--
-- map related functions
--

-- Parse extradata information
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(map, opponents)
	return {
		dateexact = map.dateexact,
		comment = map.comment,
		opponents = opponents,
	}
end

---Calculate Score and Winner of the map
---@param scoreDataInput table?
---@param scoreSettings table
---@return table
function MapFunctions.makeMapOpponentDetails(scoreDataInput, scoreSettings)
	if not scoreDataInput then
		return {}
	end

	local scoreBreakdown = {}

	local placement, kills = tonumber(scoreDataInput[1]), tonumber(scoreDataInput[2])
	if placement and kills then
		scoreBreakdown.placePoints = scoreSettings.placement[placement] or 0
		scoreBreakdown.killPoints = kills * scoreSettings.kill
		scoreBreakdown.kills = kills
		scoreBreakdown.totalPoints = scoreBreakdown.placePoints + scoreBreakdown.killPoints
	end
	local opponent = {
		status = MatchGroupInputUtil.STATUS.SCORE,
		scoreBreakdown = scoreBreakdown,
		placement = placement,
		score = scoreBreakdown.totalPoints,
	}

	if scoreDataInput[1] == '-' then
		opponent.status = MatchGroupInputUtil.STATUS.FORFIET
		opponent.score = 0
	end

	return opponent
end

return CustomMatchGroupInput
