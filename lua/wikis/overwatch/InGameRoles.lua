---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['dps'] = {category = 'DPS Players', display = 'DPS'},
	['flex'] = {category = 'Flex Players', display = 'Flex'},
	['support'] = {category = 'Support Players', display = 'Support'},
	['tank'] = {category = 'Tank Players', display = 'Tank'},
}

inGameRoles.sup = inGameRoles.support

return inGameRoles
