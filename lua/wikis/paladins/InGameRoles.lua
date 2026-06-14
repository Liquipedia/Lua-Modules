---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	damage = {category = 'Damage', display = 'Damage', sortOrder = 1},
	flanker = {category = 'Flanker', display = 'Flanker', sortOrder = 2},
	frontline = {category = 'Frontline', display = 'Frontline', sortOrder = 3},
	support = {category = 'Support', display = 'Support', sortOrder = 4},
}

return inGameRoles
