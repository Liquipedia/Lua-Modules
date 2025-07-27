---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData[]
local inGameRoles = {
	['sniper'] = {category = 'Snipers', display = 'Sniper'},
	['attacker'] = {category = 'Attackers', display = 'ATKs'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leader'},
	['fragger'] = {category = 'Fraggers', display = 'Fragger'},
	['scout'] = {category = 'Scouts', display = 'Scout'},
	['support'] = {category = 'Supports', display = 'Support'},
	['entry fragger'] = {category = 'Entry fraggers', display = 'Entry Fragger'},
	['rifler'] = {category = 'Riflers', display = 'Rifler'},
}

return inGameRoles
