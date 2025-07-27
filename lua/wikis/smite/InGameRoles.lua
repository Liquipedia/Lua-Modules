---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData[]
local inGameRoles = {
	['solo'] = {category = 'Solo players', display = 'Solo'},
	['jungler'] = {category = 'Jungle players', display = 'Jungler'},
	['support'] = {category = 'Support players', display = 'Support'},
	['mid'] = {category = 'Mid Lane players', display = 'Mid'},
	['carry'] = {category = 'Carry players', display = 'Carry'},
}

return inGameRoles
