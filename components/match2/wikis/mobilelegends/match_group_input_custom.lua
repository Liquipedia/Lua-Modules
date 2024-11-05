---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local ChampionNames = mw.loadData('Module:HeroNames')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

local DEFAULT_BESTOF_MATCH = 3
MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.OPPONENT_CONFIG = {}
MatchFunctions.DATE_FALLBACKS = {
	'tournament_enddate',
}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param match table
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	local maps = {}
	for key, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.vod = map.vod or String.nilIfEmpty(match['vodgame' .. mapIndex])
		map.participants = MapFunctions.getParticipants(map, opponents)
		map.extradata = MapFunctions.getExtraData(map, #opponents)

		local opponentInfo = Array.map(opponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			return {score = score, status = status}
		end)

		map.finished = MatchGroupInputUtil.mapIsFinished(map, opponentInfo)

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
---@param bestOf integer
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps, bestOf)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(Logic.emptyOr(bestofInput, Variables.varDefault('bestof')))
	Variables.varDefine('bestof', bestof)
	return bestof or DEFAULT_BESTOF_MATCH
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
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(map, opponentCount)
	local extradata = {
		comment = map.comment,
		team1side = string.lower(map.team1side or ''),
		team2side = string.lower(map.team2side or ''),
	}

	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, ChampionNames)
	for opponentIndex = 1, opponentCount do
		for _, ban, idx in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'b') do
			extradata['team' .. opponentIndex .. 'ban' .. idx] = getCharacterName(ban)
		end
		for _, pick, idx in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'h') do
			extradata['team' .. opponentIndex .. 'champion' .. idx] = getCharacterName(pick)
		end
	end

	return extradata
end

---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getParticipants(map, opponents)
	local allParticipants = {}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, ChampionNames)
	Array.forEach(opponents, function(opponent, opponentIndex)
		local players = Array.mapIndexes(function(playerIndex)
			return opponent.match2players[playerIndex] or Logic.nilIfEmpty(map['t' .. opponentIndex .. 'h' .. playerIndex])
		end)
		local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
			opponent.match2players,
			players,
			function(playerIndex)
				local player = map['t' .. opponentIndex .. 'p' .. playerIndex]
				return player and {name = player} or nil
			end,
			function(playerIndex, playerIdData)
				local character = map['t' .. opponentIndex .. 'h' .. playerIndex]
				return {
					champion = getCharacterName(character),
				}
			end
		)
		Array.forEach(unattachedParticipants, function(participant)
			table.insert(participants, participant)
		end)
		Table.mergeInto(allParticipants, Table.map(participants, MatchGroupInputUtil.prefixPartcipants(opponentIndex)))
	end)

	return allParticipants
end

return CustomMatchGroupInput
