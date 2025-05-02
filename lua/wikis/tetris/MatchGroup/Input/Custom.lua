---
-- @Liquipedia
-- wiki=tetris
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local CustomMatchGroupInput = {}
local MapFunctions = {
	BREAK_ON_EMPTY = true,
}

local DEFAULT_BESTOF = 99
CustomMatchGroupInput.OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
}
CustomMatchGroupInput.DEFAULT_MODE = 'solo'


-- called from Module:MatchGroup
---@param match table
---@return table
function CustomMatchGroupInput.processMatch(match)
	if Logic.readBool(match.ffa) then
		error('FFA matches are not yet supported')
	end
	if CustomMatchGroupInput._hasTeamOpponent(match) then
		error('Team opponents are currently not yet supported on tetris wiki')
	end
	return MatchGroupInputUtil.standardProcessMatch(match, CustomMatchGroupInput)
end

---@param match table
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function CustomMatchGroupInput.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param bestofInput string|integer?
---@return integer?
function CustomMatchGroupInput.getBestOf(bestofInput)
	local bestOf = tonumber(Logic.emptyOr(bestofInput, Variables.varDefault('match_bestof')))
	Variables.varDefine('match_bestof', bestOf)
	return bestOf or DEFAULT_BESTOF
end

---@param match table
---@return boolean
function CustomMatchGroupInput._hasTeamOpponent(match)
	return match.opponent1.type == Opponent.team or match.opponent2.type == Opponent.team
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

---@param map table
---@param mapIndex integer
---@param match table
---@return string?
---@return string?
function MapFunctions.getMapName(map, mapIndex, match)
	return nil
end

---@param match table
---@param map table
---@param opponents table[]
---@return string?
function MapFunctions.getMapMode(match, map, opponents)
	return Opponent.toMode(opponents[1].type, opponents[2].type)
end

return CustomMatchGroupInput
