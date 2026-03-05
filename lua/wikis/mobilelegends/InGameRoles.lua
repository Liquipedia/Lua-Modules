---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['exp lane'] = {category = 'EXP Laner', display = 'EXP Laner', sortOrder = 1},
	['gold lane'] = {category = 'Gold Laner', display = 'Gold Laner', sortOrder = 4},
	['middle'] = {category = 'Mid Laner', display = 'Mid Laner', sortOrder = 3},
	['jungler'] = {category = 'Jungler', display = 'Jungler', sortOrder = 2},
	['roamer'] = {category = 'Roamer', display = 'Roamer', sortOrder = 5},
	['flex'] = {category = 'Flex', display = 'Flex', sortOrder = 6},
}

inGameRoles['jgl'] = inGameRoles.jungler
inGameRoles['jungle'] = inGameRoles.jungler
inGameRoles['roam'] = inGameRoles.roamer
inGameRoles['support'] = inGameRoles.roamer
inGameRoles['top'] = inGameRoles['exp lane']
inGameRoles['exp'] = inGameRoles['exp lane']
inGameRoles['mid laner'] = inGameRoles.middle
inGameRoles['mid'] = inGameRoles.middle
inGameRoles['bottom'] = inGameRoles['gold lane']
inGameRoles['gold'] = inGameRoles['gold lane']

return inGameRoles
