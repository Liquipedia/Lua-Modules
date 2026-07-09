---
-- @Liquipedia
-- page=Module:PlayerTeamRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local playerTeamRoles = {
	['captain'] = {category = 'Captains', display = 'Captain', iconFa = 'captain'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leader', iconFa = 'captain', abbreviation = 'IGL'},
}

playerTeamRoles['in-game leader'] = playerTeamRoles.igl

return playerTeamRoles
