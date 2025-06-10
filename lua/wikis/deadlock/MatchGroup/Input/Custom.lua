---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local HeroNames = mw.loadData('Module:HeroNames')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local MatchFunctions = {}
local MapFunctions = {}
local CustomMatchGroupInput = {}

MatchFunctions.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
	maxNumPlayers = 10,
}
MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

---@param match table
---@param options? {isMatchPage: boolean?}
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

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param map table
---@param mapIndex table
---@param match table
---@return string?
---@return string?
function MapFunctions.getMapName(map, mapIndex, match)
	return nil
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local extradata = {
		team1side = map.team1side,
		team2side = map.team2side,
	}

	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, HeroNames)
	for opponentIndex = 1, #opponents do
		for _, ban, banIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'b') do
			extradata['team' .. opponentIndex .. 'ban' .. banIndex] = getCharacterName(ban)
		end
		for _, pick, pickIndex in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'h') do
			extradata['team' .. opponentIndex .. 'hero' .. pickIndex] = getCharacterName(pick)
		end
	end

	return extradata
end

--- TODO FIX:This function does not attempt to attach the data to the correct player!
---@param map table
---@param opponent table
---@param opponentIndex integer
---@return table[]
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local getCharacterName = FnUtil.curry(MatchGroupInputUtil.getCharacterName, HeroNames)

	local participants = {}
	for _, hero in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'h', {requireIndex = true}) do
		table.insert(participants, {character = getCharacterName(hero)})
	end

	return participants
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
