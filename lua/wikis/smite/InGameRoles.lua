---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['solo'] = {category = 'Solo players', display = 'Solo', sortOrder = 1},
	['jungler'] = {category = 'Jungle players', display = 'Jungler', sortOrder = 2},
	['mid'] = {category = 'Mid Lane players', display = 'Mid', sortOrder = 3},
	['support'] = {category = 'Support players', display = 'Support', sortOrder = 4},
	['carry'] = {category = 'Carry players', display = 'Carry', sortOrder = 5},
}

inGameRoles['guardian'] = inGameRoles.support
inGameRoles['hunter'] = inGameRoles.carry

return inGameRoles
