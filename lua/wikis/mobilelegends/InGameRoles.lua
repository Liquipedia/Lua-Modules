---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData
local inGameRoles = {
	['igl'] = {category = 'In-game leaders', display = 'In-game Leader'},
	['exp'] = {category = 'EXP Laner', display = 'EXP Laner'},
	['gold'] = {category = 'Gold Laner', display = 'Gold Laner'},
	['mid'] = {category = 'Mid Laner', display = 'Mid Laner'},
	['jungler'] = {category = 'Jungler', display = 'Jungler'},
	['roamer'] = {category = 'Roamer', display = 'Roamer'},
}

inGameRoles['jgl'] = inGameRoles.jungler
inGameRoles['jungle'] = inGameRoles.jungler
inGameRoles['roam'] = inGameRoles.roamer
inGameRoles['support'] = inGameRoles.roamer
inGameRoles['top'] = inGameRoles.exp
inGameRoles['mid laner'] = inGameRoles.mid
inGameRoles['bottom'] = inGameRoles.gold

return inGameRoles
