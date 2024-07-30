---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchGroupInputNormal = {}

local MAX_NUM_PICKS = 5
local MAX_NUM_BANS = 5

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
	local team = map['t' .. opponentIndex]
	for playerIndex = 1, MAX_NUM_PICKS do
		table.insert(picks, map[team .. 'c' .. playerIndex])
	end
	return picks
end

function CustomMatchGroupInputNormal.getHeroBans(map, opponentIndex)
	local bans = {}
	local team = map['t' .. opponentIndex]
	for playerIndex = 1, MAX_NUM_BANS do
		table.insert(bans, map[team .. 'c' .. playerIndex])
	end
	return bans
end


function CustomMatchGroupInputNormal.getVetoPhase(map)
	return
end

return CustomMatchGroupInputNormal
