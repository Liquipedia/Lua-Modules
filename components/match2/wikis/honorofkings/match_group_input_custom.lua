---
-- @Liquipedia
-- wiki=honorofkings
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local ChampionNames = mw.loadData('Module:HeroNames')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = false,
	maxNumPlayers = 5,
}
MatchFunctions.DATE_FALLBACKS = {
	'tournament_enddate',
	'tournament_startdate',
}

local MAX_NUM_PLAYERS = 5
local DEFAULT_BESTOF = 3
local DUMMY_MAP = 'default'

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		if map.map == DUMMY_MAP then
			map.map = nil
		end

		map.extradata = MapFunctions.getExtraData(map, #opponents)

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		local opponentInfo = Array.map(opponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map.winner, map.finished))
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

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestOf = tonumber(Logic.emptyOr(bestofInput, Variables.varDefault('bestof')))
	Variables.varDefine('bestof', bestOf)
	return bestOf or DEFAULT_BESTOF
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
			local pick = getCharacterName(map['t' .. opponentIndex .. 'h' .. playerIndex])
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
