---
-- @Liquipedia
-- wiki=teamfortress
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')

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
	match.bestof = MatchGroupInput.getBestOf(match.bestof, games)

	local autoScoreFunction = MatchGroupInput.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games)
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
	match.links = MatchFunctions.getLinks(match, games)
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

		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInput.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInput.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
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

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInput.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode'), DEFAULT_MODE)
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@param games table[]
---@return table
function MatchFunctions.getLinks(match, games)
	local links = {
		rgl = match.rgl and 'https://rgl.gg/Public/Match.aspx?m=' .. match.rgl or nil,
		ozf = match.ozf and 'https://warzone.ozfortress.com/matches/' .. match.ozf or nil,
		etf2l = match.etf2l and 'http://etf2l.org/matches/' .. match.etf2l or nil,
		tftv = match.tftv and'http://tf.gg/' .. match.tftv or nil,
		esl = match.esl and 'https://play.eslgaming.com/match/' .. match.esl or nil,
		esea = match.esea and 'https://play.esea.net/match/' .. match.esea or nil,
		logstf = {},
		logstfgold = {},
	}

	Array.forEach(games or {}, function(game, gameIndex)
		links.logstf[gameIndex] = game.logstf and ('https://logs.tf/' .. game.logstf) or nil
		links.logstfgold[gameIndex] = game.logstfgold and ('https://logs.tf/' .. game.logstfgold) or nil
	end)

	return links
end

--
-- map related functions
--

-- Parse extradata information
---@param map table
---@return table
function MapFunctions.getExtraData(map)
	return {
		comment = map.comment,
	}
end

return CustomMatchGroupInput