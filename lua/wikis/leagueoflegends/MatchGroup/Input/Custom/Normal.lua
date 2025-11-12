---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom/Normal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local InGameRoles = Lua.import('Module:InGameRoles', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

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
	return Logic.nilIfEmpty(Array.map(Array.range(1, MAX_NUM_PICKS), function (playerIndex)
		local playerData = Json.parseIfTable(map['t' .. opponentIndex .. 'p' .. playerIndex])
		if Logic.isEmpty(playerData) then
			return
		end
		---@cast playerData -nil
		if Logic.isEmpty(playerData.role) then
			return playerData
		end
		local playerRole = InGameRoles[playerData.role]
		assert(playerRole, 'Invalid |role=' .. playerData.role)
		return playerData
	end))
end

---@param map table
---@param opponentIndex integer
---@return string[]
function CustomMatchGroupInputNormal.getHeroPicks(map, opponentIndex)
	local participants = CustomMatchGroupInputNormal.getParticipants(map, opponentIndex)
	if Logic.isNotEmpty(participants) then
		---@cast participants -nil
		return Array.map(participants, Operator.property('character'))
	end
	local picks = {}
	local teamPrefix = 't' .. opponentIndex
	for playerIndex = 1, MAX_NUM_PICKS do
		table.insert(picks, map[teamPrefix .. 'c' .. playerIndex])
	end
	return picks
end

---@param map table
---@param opponentIndex integer
---@return string[]
function CustomMatchGroupInputNormal.getHeroBans(map, opponentIndex)
	local bans = {}
	local teamPrefix = 't' .. opponentIndex
	for playerIndex = 1, MAX_NUM_BANS do
		table.insert(bans, map[teamPrefix .. 'b' .. playerIndex])
	end
	return bans
end

---@param map table
---@return table?
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
