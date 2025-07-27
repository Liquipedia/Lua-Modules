---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--


local Array = require('Module:Array')
local Lua = require('Module:Lua')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}
MatchFunctions.DEFAULT_MODE = '2v2'
MatchFunctions.DATE_FALLBACKS = {'tournament_enddate'}
MatchFunctions.getBestOf = MatchGroupInputUtil.getBestOf

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

---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
	end)
end

---@param match table
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, opponents)
	return {
		isfeatured = MatchFunctions.isFeatured(tonumber(match.liquipediatier)),
	}
end

---@param tier integer?
---@return boolean
function MatchFunctions.isFeatured(tier)
	return tier == 1 or tier == 2
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
		ot = map.ot,
		otlength = map.otlength,
	}
end

return CustomMatchGroupInput
