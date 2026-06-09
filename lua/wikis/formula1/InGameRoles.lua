---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['driver'] = {category = 'Drivers', display = 'Driver', sortOrder = 1},
	['reserve'] = {category = 'Reserve Drivers', display = 'Reserve Driver', sortOrder = 2},
	['test'] = {category = 'Test Drivers', display = 'Test Driver', sortOrder = 3},
}

inGameRoles['reserve driver'] = inGameRoles.reserve
inGameRoles['test driver'] = inGameRoles.test

return inGameRoles
