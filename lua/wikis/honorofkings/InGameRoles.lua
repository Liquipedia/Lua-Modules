---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['top'] = {category = 'Top Laners', display = 'Top Lane', sortOrder = 1},
	['bottom'] = {category = 'Bottom Laners', display = 'Bottom Laner', sortOrder = 5},
	['mid'] = {category = 'Mid Laners', display = 'Mid Laner', sortOrder = 4},
	['side lane'] = {category = 'Side Laners', display = 'Side Laner', sortOrder = 2},
	['jungler'] = {category = 'Junglers', display = 'Jungler', sortOrder = 3},
	['roamer'] = {category = 'Roamers', display = 'Roamer', sortOrder = 6},
	['flex'] = {category = 'Flex', display = 'Flex', sortOrder = 7},
}

inGameRoles['jgl'] = inGameRoles.jungler
inGameRoles['jungle'] = inGameRoles.jungler
inGameRoles['support'] = inGameRoles.roamer
inGameRoles['roam'] = inGameRoles.roamer
inGameRoles['sup'] = inGameRoles.roamer
inGameRoles['ad lane'] = inGameRoles.bottom
inGameRoles['ad carry'] = inGameRoles.bottom
inGameRoles['abyssal dragon lane'] = inGameRoles.bottom
inGameRoles['adl'] = inGameRoles.bottom
inGameRoles['adc'] = inGameRoles.bottom
inGameRoles['bot'] = inGameRoles.bottom
inGameRoles['carry'] = inGameRoles.bottom
inGameRoles['farm'] = inGameRoles.bottom
inGameRoles['mid laner'] = inGameRoles.mid
inGameRoles['ds lane'] = inGameRoles.top
inGameRoles['dsl'] = inGameRoles.top
inGameRoles['dark slayer lane'] = inGameRoles.top
inGameRoles['confront'] = inGameRoles.top
inGameRoles['clash'] = inGameRoles.top
inGameRoles['fill'] = inGameRoles.flex

return inGameRoles
