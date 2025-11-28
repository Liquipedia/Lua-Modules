---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['dps'] = {category = 'DPS Players', display = 'DPS', sortOrder = 1},
	['flex'] = {category = 'Flex Players', display = 'Flex', sortOrder = 4},
	['support'] = {category = 'Support Players', display = 'Support', sortOrder = 3},
	['tank'] = {category = 'Tank Players', display = 'Tank', sortOrder =2},
}

inGameRoles.sup = inGameRoles.support

return inGameRoles
