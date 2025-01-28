---
-- @Liquipedia
-- wiki=chess
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local Eco = Lua.import('Module:Chess/ECO')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local CustomMatchGroupInput = {}
local MatchFunctions = {
	DEFAULT_MODE = 'solo',
	getBestOf = MatchGroupInputUtil.getBestOf,
}
local MapFunctions = {}

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

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return (map.winner == opponentIndex and 1 or map.winner == 0 and 0.5 or 0)
		end), Operator.add)
	end
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
		white = tonumber(map.white),
		movecount = tonumber(map.length),
		eco = Eco.sanitise(map.eco),
		links = MatchGroupInputUtil.getLinks(map),
	}
end

return CustomMatchGroupInput
