---
-- @Liquipedia
-- wiki=valorant
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

function CustomMatchGroupInputNormal.getParticipants(map, opponentIndex)
	return Array.mapIndexes(function(playerIndex)
		return Json.parseIfString(map['t' .. opponentIndex .. 'p' .. playerIndex])
	end)
end

function CustomMatchGroupInputNormal.getFirstSide(map, opponentIndex)
	return map['t' .. opponentIndex .. 'firstside']
end

function CustomMatchGroupInputNormal.getScoreFromRounds(map, side, opponentIndex)
	return tonumber(map['t'.. opponentIndex .. side ])
end

return CustomMatchGroupInputNormal
