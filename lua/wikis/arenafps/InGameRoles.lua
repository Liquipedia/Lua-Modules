---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData
local inGameRoles = {
	['duel'] = {category = 'Duel', display = 'Duel'},
	['tdm'] = {category = 'TDM', display = 'TDM'},
	['ctf'] = {category = 'CTF', display = 'CTF'},
	['sacrifice'] = {category = 'Sacrifice', display = 'Sacrifice'},
	['3vs3'] = {category = '3vs3', display = '3vs3'},
}

inGameRoles['dueler'] = inGameRoles.duel

return inGameRoles
