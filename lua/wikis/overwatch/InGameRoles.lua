---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData[]
local inGameRoles = {
	['dps'] = {category = 'DPS Players', display = 'DPS'},
	['flex'] = {category = 'Flex Players', display = 'Flex'},
	['support'] = {category = 'Support Players', display = 'Support'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leader'},
	['tank'] = {category = 'Tank Players', display = 'Tank'},
}

return inGameRoles
