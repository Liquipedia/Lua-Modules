---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local ChampionNames = mw.loadData('Module:ChampionNames')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local MAX_NUM_PLAYERS = 5
local DEFAULT_BESTOF = 3
local DEFAULT_MODE = 'team'
local DUMMY_MAP = 'default'

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = false,
	pagifyPlayerNames = true,
}

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]
	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date, {
		'tournament_enddate',
		'tournament_startdate',
	}))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)
	local games = CustomMatchGroupInput.extractMaps(match, #opponents)
	match.bestof = MatchFunctions.getBestOf(match)

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
		MatchGroupInputUtil.setPlacement(opponents, match.winner, 1, 2)
	elseif MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput) then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.winner = nil
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
---@param opponentCount integer
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponentCount)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		if map.map == DUMMY_MAP then
			map.map = nil
		end

		map.extradata = MapFunctions.getExtraData(map, opponentCount)

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map.winner, map.finished))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished or MatchGroupInputUtil.isNotPlayed(map.winner, finishedInput) then
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

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return integer
function MatchFunctions.getBestOf(match)
	local bestOf = tonumber(Logic.emptyOr(match.bestof, Variables.varDefault('bestof')))
	Variables.varDefine('bestof', bestOf)
	return bestOf or DEFAULT_BESTOF
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	return MatchGroupInputUtil.getCommonTournamentVars(match)
end

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	return {
		reddit = match.reddit,
	}
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mvp = MatchGroupInputUtil.readMvp(match),
	}
end

--
-- map related functions
--

-- Parse extradata information
---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(map, opponentCount)
	local extraData = {
		comment = map.comment,
	}

	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, ChampionNames)

	for opponentIndex = 1, opponentCount do
		extraData['team' .. opponentIndex .. 'side'] = string.lower(map['team' .. opponentIndex .. 'side'] or '')
		for playerIndex = 1, MAX_NUM_PLAYERS do
			local pick = getCharacterName(map['t' .. opponentIndex .. 'c' .. playerIndex])
			extraData['team' .. opponentIndex .. 'champion' .. playerIndex] = pick
			local ban = getCharacterName(map['t' .. opponentIndex .. 'b' .. playerIndex])
			extraData['team' .. opponentIndex .. 'ban' .. playerIndex] = ban
		end
	end

	return extraData
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

return CustomMatchGroupInput
