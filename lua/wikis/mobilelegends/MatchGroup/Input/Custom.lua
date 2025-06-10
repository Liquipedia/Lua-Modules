---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
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
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
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
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
	}
end

--
-- map related functions
--

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local extradata = {
		team1side = string.lower(map.team1side or ''),
		team2side = string.lower(map.team2side or ''),
	}

	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, ChampionNames)
	for opponentIndex = 1, #opponents do
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
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, ChampionNames)
	local players = Array.mapIndexes(function(playerIndex)
		return map['t' .. opponentIndex .. 'p' .. playerIndex] or map['t' .. opponentIndex .. 'h' .. playerIndex]
	end)
	return MatchGroupInputUtil.parseMapPlayers(
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
end

return CustomMatchGroupInput
