---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@class LeagueOfLegendsNormalMapParser: LeagueOfLegendsMapParserInterface
local CustomMatchGroupInputNormal = {}

local MAX_NUM_PICKS = 5
local MAX_NUM_BANS = 5

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
	local picks = {}
	local teamPrefix = 't' .. opponentIndex
	for playerIndex = 1, MAX_NUM_PICKS do
		table.insert(picks, map[teamPrefix .. 'c' .. playerIndex])
	end
	return picks
end

---@param map table
---@param opponentIndex integer
---@return string[]?
function CustomMatchGroupInputNormal.getHeroBans(map, opponentIndex)
	local bans = {}
	local teamPrefix = 't' .. opponentIndex
	for playerIndex = 1, MAX_NUM_BANS do
		table.insert(bans, map[teamPrefix .. 'b' .. playerIndex])
	end
	return bans
end

---@param map table
---@return table[]?
function CustomMatchGroupInputNormal.getVetoPhase(map)
	return
end

---@param map table
---@param opponentIndex integer
---@return table<string, integer>?
function CustomMatchGroupInputNormal.getObjectives(map, opponentIndex)
	return
end

return CustomMatchGroupInputNormal
