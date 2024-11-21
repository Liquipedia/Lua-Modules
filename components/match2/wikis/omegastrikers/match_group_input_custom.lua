---
-- @Liquipedia
-- wiki=omegastrikers
-- page=Module:MatchGroup/Input/Custom
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
local StrikerNames = mw.loadData('Module:StrikerNames')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

local DEFAULT_BESTOF_MATCH = 5
local DEFAULT_BESTOF_MAP = 3
MatchFunctions.DEFAULT_MODE = 'team'

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
		if not map.map then
			break
		end
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.bestof = MapFunctions.getBestOf(map)
		map.extradata = MapFunctions.getExtraData(map, #opponents)

		map.opponents = Array.map(opponents, function(opponent, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			local players = MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
			return {score = score, status = status, players = players}
		end)

		map.finished = MatchGroupInputUtil.mapIsFinished(map, map.opponents)

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

--
-- match related functions
--

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
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

--
-- map related functions
--

---@param map table
---@return integer
function MapFunctions.getBestOf(map)
	local bestof = tonumber(Logic.emptyOr(map.bestof, Variables.varDefault('map_bestof')))
	Variables.varDefine('map_bestof', bestof)
	return bestof or DEFAULT_BESTOF_MAP
end

---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getExtraData(map, opponentCount)
	local extradata = {
		bestof = map.bestof,
		comment = map.comment,
	}

	local bans = {}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, StrikerNames)
	for opponentIndex = 1, opponentCount do
		bans['team' .. opponentIndex] = {}
		for _, ban in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'b') do
			ban = getCharacterName(ban)
			table.insert(bans['team' .. opponentIndex], ban)
		end
	end

	extradata.bans = bans

	return extradata
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, StrikerNames)
	local players = Array.mapIndexes(function(playerIndex)
		return opponent.match2players[playerIndex] or Logic.nilIfEmpty(map['t' .. opponentIndex .. 'c' .. playerIndex])
	end)
	local participants, unattachedParticipants = MatchGroupInputUtil.parseParticipants(
		opponent.match2players,
		players,
		function(playerIndex)
			local player = map['t' .. opponentIndex .. 'p' .. playerIndex]
			return player and {name = player} or nil
		end,
		function(playerIndex, playerIdData)
			local striker = map['t' .. opponentIndex .. 'c' .. playerIndex]
			return {
				player = playerIdData.name,
				striker = getCharacterName(striker),
			}
		end
	)
	Array.forEach(unattachedParticipants, function(participant)
		table.insert(participants, participant)
	end)
	return participants
end

return CustomMatchGroupInput
