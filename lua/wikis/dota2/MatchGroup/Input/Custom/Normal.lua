---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchGroupInputNormal = {}

local MAX_NUM_PICKS = 5
local MAX_NUM_BANS = 7

function CustomMatchGroupInputNormal.getMap(mapInput)
	return mapInput
end

function CustomMatchGroupInputNormal.getLength(map)
	return map.length
end

function CustomMatchGroupInputNormal.getSide(map, opponentIndex)
	local side = map['team' .. opponentIndex .. 'side']
	if not side then
		return
	end
	return string.lower(side)
end

function CustomMatchGroupInputNormal.getParticipants(map, opponentIndex)
	return
end

function CustomMatchGroupInputNormal.getHeroPicks(map, opponentIndex)
	local picks = {}
	local teamPrefix = 't' .. opponentIndex
	for playerIndex = 1, MAX_NUM_PICKS do
		table.insert(picks, map[teamPrefix .. 'h' .. playerIndex])
	end
	return picks
end

function CustomMatchGroupInputNormal.getHeroBans(map, opponentIndex)
	local bans = {}
	local teamPrefix = 't' .. opponentIndex
	for playerIndex = 1, MAX_NUM_BANS do
		table.insert(bans, map[teamPrefix .. 'b' .. playerIndex])
	end
	return bans
end

function CustomMatchGroupInputNormal.getVetoPhase(map)
	return
end

function CustomMatchGroupInputNormal.getObjectives(map, opponentIndex)
	return
end

return CustomMatchGroupInputNormal
