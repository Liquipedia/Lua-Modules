---
-- @Liquipedia
-- wiki=crossfire
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
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
	maxNumPlayers = 5
}

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

---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
	end)
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

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mvp = MatchGroupInputUtil.readMvp(match, opponents),
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
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
	return {
		comment = map.comment,
	}
end

return CustomMatchGroupInput
