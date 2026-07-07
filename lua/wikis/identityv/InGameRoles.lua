---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['survivor'] = {category = 'Survivors', display = 'Survivor', sortOrder = 1},
	['hunter'] = {category = 'Hunters', display = 'Hunter', sortOrder = 2},
	['dual'] = {category = 'Dual Roles', display = 'Dual', sortOrder = 3},
}

return inGameRoles
