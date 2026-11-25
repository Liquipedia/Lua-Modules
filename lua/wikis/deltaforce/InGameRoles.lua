---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['commander'] = {category = 'Commanders', display = 'Commander', sortOrder = 1},
	['squad leader'] = {category = 'Squad Leaders', display = 'Squad Leader', sortOrder = 2},
}

return inGameRoles
