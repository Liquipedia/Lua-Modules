---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local Eco = Lua.import('Module:ChessOpenings')
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

---@param match table
---@param games table[]
---@return table
function MatchFunctions.getLinks(match, games)
	---@type table<string, string|table|nil>
	local links = MatchGroupInputUtil.getLinks(match)

	Array.forEach(games, function(game, gameIndex)
		local gameLinks = MatchGroupInputUtil.getLinks(game)
		for key, link in pairs(gameLinks) do
			if type(links[key]) ~= 'table' then
				links[key] = {[0] = links[key]}
			end
			links[key][gameIndex] = link
		end
	end)

	return links
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
		header = map.header,
		eco = Eco.sanitise(map.eco),
	}
end

---@param map table
---@param opponentIndex integer
---@return table
function MapFunctions.extendMapOpponent(map, opponentIndex)
	local whiteSide = tonumber(map.white)
	return {
		color = (whiteSide == opponentIndex and 'white')
			or (whiteSide ~= nil and 'black')
			or nil
	}
end

return CustomMatchGroupInput
