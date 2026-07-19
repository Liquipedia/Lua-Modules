---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['sniper'] = {category = 'Snipers', display = 'Sniper'},
	['attacker'] = {category = 'Attackers', display = 'ATKs'},
	['fragger'] = {category = 'Fraggers', display = 'Fragger'},
	['scout'] = {category = 'Scouts', display = 'Scout'},
	['support'] = {category = 'Supports', display = 'Support'},
	['entry fragger'] = {category = 'Entry fraggers', display = 'Entry Fragger'},
	['rifler'] = {category = 'Riflers', display = 'Rifler'},
}

return inGameRoles
