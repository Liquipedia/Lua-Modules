---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')

---@class Dota2NormalMapParser: Dota2MapParserInterface
local CustomMatchGroupInputNormal = {}

local MAX_NUM_PICKS = 5
local MAX_NUM_BANS = 7

---@param mapInput table
---@return table
function CustomMatchGroupInputNormal.getMap(mapInput)
	return mapInput
end

---@param map table
---@return string?
function CustomMatchGroupInputNormal.getLength(map)
	return map.length
end

---@param map table
---@param opponentIndex integer
---@return string?
function CustomMatchGroupInputNormal.getSide(map, opponentIndex)
	local side = map['team' .. opponentIndex .. 'side']
	if not side then
		return
	end
	return string.lower(side)
end

---@param map table
---@param opponentIndex integer
---@return table[]?
function CustomMatchGroupInputNormal.getParticipants(map, opponentIndex)
	return
end

---@param map table
---@param opponentIndex integer
---@return string[]?
function CustomMatchGroupInputNormal.getHeroPicks(map, opponentIndex)
	local teamPrefix = 't' .. opponentIndex
	return Array.map(Array.range(1, MAX_NUM_PICKS), function (playerIndex)
		return map[teamPrefix .. 'h' .. playerIndex]
	end)
end

---@param map table
---@param opponentIndex integer
---@return string[]?
function CustomMatchGroupInputNormal.getHeroBans(map, opponentIndex)
	local teamPrefix = 't' .. opponentIndex
	return Array.map(Array.range(1, MAX_NUM_BANS), function (banIndex)
		return map[teamPrefix .. 'b' .. banIndex]
	end)
end

---@param map table
---@return table[]?
function CustomMatchGroupInputNormal.getVetoPhase(map)
	return
end

---@param map table
---@param opponentIndex integer
---@return table?
function CustomMatchGroupInputNormal.getObjectives(map, opponentIndex)
	return
end

return CustomMatchGroupInputNormal
