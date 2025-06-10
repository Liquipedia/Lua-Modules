---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData
local inGameRoles = {
	['igl'] = {category = 'In-game leaders', display = 'In-game Leader'},
	['rifler'] = {category = 'Riflers', display = 'Rifler'},
}

inGameRoles['rifle'] = inGameRoles['rifler']

return inGameRoles
