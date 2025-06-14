---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')

local CustomMatchGroupInputNormal = {}

function CustomMatchGroupInputNormal.getMap(mapInput)
	return mapInput
end

function CustomMatchGroupInputNormal.getMapName(mapInput)
	return mapInput.map
end

---@param map table
---@return string?, string?
function CustomMatchGroupInputNormal.getMatchId(map)
	return map.matchid, map.region
end

function CustomMatchGroupInputNormal.getLength(mapInput)
	return mapInput.length
end

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

function CustomMatchGroupInputNormal.getScoreFromRounds(map, side, opponentIndex)
	return tonumber(map['t'.. opponentIndex .. side ])
end

function CustomMatchGroupInputNormal.getRounds(map)
	return nil
end

function CustomMatchGroupInputNormal.getPatch(map)
	return map.patch
end

return CustomMatchGroupInputNormal
