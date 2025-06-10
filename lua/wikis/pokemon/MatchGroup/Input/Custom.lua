---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ChampionNames = mw.loadData('Module:HeroNames')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

local DEFAULT_BESTOF = 3
MatchFunctions.DEFAULT_MODE = 'team'
MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	maxNumPlayers = 5,
}
MatchFunctions.DATE_FALLBACKS = {
	'tournament_enddate',
	'tournament_startdate',
}


-- called from Module:MatchGroup
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
		for _, ban, banIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'b') do
			extradata['team' .. opponentIndex .. 'ban' .. banIndex] = getCharacterName(ban)
		end
		for _, pick, pickIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'h') do
			extradata['team' .. opponentIndex .. 'champion' .. pickIndex] = getCharacterName(pick)
		end
	end

	return extradata
end

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

return CustomMatchGroupInput
