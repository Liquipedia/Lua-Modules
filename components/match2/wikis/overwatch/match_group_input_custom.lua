---
-- @Liquipedia
-- wiki=overwatch
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

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local DEFAULT_BESTOF = 3

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

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, {})
	end)
	local games = CustomMatchGroupInput.extractMaps(match, #opponents)
	match.bestof = MatchFunctions.getBestOf(match)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games, match.bestof)
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
		MatchGroupInputUtil.setPlacement(opponents, match.winner, 1, 2, match.resulttype)
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

		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local scoreInput = map['score' .. opponentIndex]
			if map.mode == 'Push' and scoreInput then
				scoreInput = scoreInput:gsub('m', '')
			end
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = scoreInput,
			})
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
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
---@param bestOf integer
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps, bestOf)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return integer
function MatchFunctions.getBestOf(match)
	local bestof = tonumber(Logic.emptyOr(match.bestof, Variables.varDefault('bestof')))
	Variables.varDefine('bestof', bestof)
	return bestof or DEFAULT_BESTOF
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	return MatchGroupInputUtil.getCommonTournamentVars(match)
end

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	return {
		owl = match.owl and 'https://web.archive.org/web/overwatchleague.com/en-us/match/' .. match.owl or nil,
		jcg = match.jcg and 'https://web.archive.org/web/ow.j-cg.com/compe/view/match/' .. match.jcg or nil,
		tespa = match.tespa and 'https://web.archive.org/web/compete.tespa.org/tournament/' .. match.tespa or nil,
		overgg = match.overgg and 'http://www.over.gg/' .. match.overgg or nil,
		pf = match.pf and 'http://www.plusforward.net/overwatch/post/' .. match.pf or nil,
		wl = match.wl and 'https://www.winstonslab.com/matches/match.php?id=' .. match.wl or nil,
		faceit = match.faceit and 'https://www.faceit.com/en/ow2/room/' .. match.faceit or nil,
		stats = match.stats,
	}
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	return {
		mvp = MatchGroupInputUtil.readMvp(match),
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end

--
-- map related functions
--

---@param map table
---@return table
function MapFunctions.getExtraData(map)
	return {
		comment = map.comment,
	}
end

return CustomMatchGroupInput
