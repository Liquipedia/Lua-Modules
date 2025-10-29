---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--- copied from LAB until we have a proper match2 setup for this wiki

local Lua = require('Module:Lua')

local FnUtil = Lua.import('Module:FnUtil')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {
	DEFAULT_MODE = 'team',
	getBestOf = MatchGroupInputUtil.getBestOf,
}
local MapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

-- "Normal" match
---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return FnUtil.cuury(MatchGroupInputUtil.computeMatchScoreFromMapWinners, maps)
end

return CustomMatchGroupInput
