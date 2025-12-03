---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['igl'] = {category = 'In-game leaders', display = 'In-game Leader'},
	['exp'] = {category = 'EXP Laner', display = 'EXP Laner', sortOrder = 1},
	['gold'] = {category = 'Gold Laner', display = 'Gold Laner', sortOrder = 4},
	['mid'] = {category = 'Mid Laner', display = 'Mid Laner', sortOrder = 3},
	['jungler'] = {category = 'Jungler', display = 'Jungler', sortOrder = 2},
	['roamer'] = {category = 'Roamer', display = 'Roamer', sortOrder = 5},
}

inGameRoles['jgl'] = inGameRoles.jungler
inGameRoles['jungle'] = inGameRoles.jungler
inGameRoles['roam'] = inGameRoles.roamer
inGameRoles['support'] = inGameRoles.roamer
inGameRoles['top'] = inGameRoles.exp
inGameRoles['mid laner'] = inGameRoles.mid
inGameRoles['bottom'] = inGameRoles.gold

return inGameRoles
