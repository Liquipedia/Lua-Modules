---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')

---@class ValorantNormalMapParser: ValorantMapParserInterface
local CustomMatchGroupInputNormal = {}

---@param mapInput table
---@return table
function CustomMatchGroupInputNormal.getMap(mapInput)
	return mapInput
end

---@param mapInput table
---@return string?
function CustomMatchGroupInputNormal.getMapName(mapInput)
	return mapInput.map
end

---@param map table
---@return string?, string?
function CustomMatchGroupInputNormal.getMatchId(map)
	return map.matchid, map.region
end

---@param mapInput table
---@return string?
function CustomMatchGroupInputNormal.getLength(mapInput)
	return mapInput.length
end

---@param map table
---@param opponentIndex integer
---@return table[]
function CustomMatchGroupInputNormal.getParticipants(map, opponentIndex)
	return Array.mapIndexes(function(playerIndex)
		return Json.parseIfString(map['t' .. opponentIndex .. 'p' .. playerIndex])
	end)
end

---@param map table
---@param opponentIndex integer
---@param phase 'normal'|'ot'
---@return 'atk'|'def'|nil
function CustomMatchGroupInputNormal.getFirstSide(map, opponentIndex, phase)
	if phase == 'normal' then
		return map['t' .. opponentIndex .. 'firstside']
	else
		return map['t' .. opponentIndex .. 'firstsideot']
	end
end

---@param map table
---@param side 'atk'|'def'|'otatk'|'otdef'
---@param opponentIndex integer
---@return integer?
function CustomMatchGroupInputNormal.getScoreFromRounds(map, side, opponentIndex)
	return tonumber(map['t'.. opponentIndex .. side ])
end

---@param map table
---@return nil
function CustomMatchGroupInputNormal.getRounds(map)
	return nil
end

---@param map table
---@return string?
function CustomMatchGroupInputNormal.getPatch(map)
	return map.patch
end

return CustomMatchGroupInputNormal
