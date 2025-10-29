---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FnUtil = Lua.import('Module:FnUtil')
local GodNames = Lua.import('Module:GodNames', {loadData = true})
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {
	BREAK_ON_EMPTY = true,
}

local DEFAULT_BESTOF = 3
local MAX_NUM_PLAYERS = 15
MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	maxNumPlayers = MAX_NUM_PLAYERS,
}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

--
-- match related functions
--

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param bestofInput string|integer?
---@return integer?
function MatchFunctions.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput)

	if bestof then
		Variables.varDefine('bestof', bestof)
		return bestof
	end

	return tonumber(Variables.varDefault('bestof')) or DEFAULT_BESTOF
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

--
-- map related functions
--
---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return Table.merge({
		team1side = string.lower(map.team1side or ''),
		team2side = string.lower(map.team2side or ''),
	}, MapFunctions.getPicksAndBans(map, #opponents))
end

---@param map table
---@param opponentCount integer
---@return table
function MapFunctions.getPicksAndBans(map, opponentCount)
	local godData = {}
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, GodNames)
	for opponentIndex = 1, opponentCount do
		for playerIndex = 1, MAX_NUM_PLAYERS do
			local god = map['t' .. opponentIndex .. 'g' .. playerIndex]
			godData['team' .. opponentIndex .. 'god' .. playerIndex] = getCharacterName(god)

			local ban = map['t' .. opponentIndex .. 'b' .. playerIndex]
			godData['team' .. opponentIndex .. 'ban' .. playerIndex] = getCharacterName(ban)
		end
	end

	return godData
end

return CustomMatchGroupInput
