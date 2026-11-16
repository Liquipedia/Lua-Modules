---
-- @Liquipedia
-- page=Module:PortalStatistics/PlayerData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')

local Util = Lua.import('Module:PortalStatistics/Util')

--- Player queries shared by the player tables of PortalStatistics
---@class PortalStatisticsPlayerData
local PlayerData = {}

---@param limit number?
---@param addConditions string|AbstractConditionNode?
---@param addOrder string?
---@return table
function PlayerData.getPlayers(limit, addConditions, addOrder)
	return Util.massQuery('player', {
		query = 'pagename, id, nationality, earnings, birthdate, team, earningsbyyear',
		conditions = addConditions and tostring(addConditions) or '',
		order = addOrder,
		limit = limit,
	})
end

---@param player table
---@return table
function PlayerData.toOpponent(player)
	return {
		type = Opponent.solo,
		players = {{
			pageName = player.pagename,
			displayName = player.id,
			flag = player.nationality,
			team = String.isNotEmpty(player.team) and player.team or nil,
		}},
	}
end

return PlayerData
