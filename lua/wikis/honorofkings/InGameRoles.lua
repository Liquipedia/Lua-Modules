---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['top lane'] = {category = 'Top Laners', display = 'Top Lane', sortOrder = 1},
	['bottom lane'] = {category = 'Bottom Laners', display = 'Bottom Laner', sortOrder = 5},
	['middle'] = {category = 'Mid Laners', display = 'Mid Laner', sortOrder = 4},
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
inGameRoles['ad lane'] = inGameRoles['bottom lane']
inGameRoles['ad carry'] = inGameRoles['bottom lane']
inGameRoles['abyssal dragon lane'] = inGameRoles['bottom lane']
inGameRoles['adl'] = inGameRoles['bottom lane']
inGameRoles['adc'] = inGameRoles['bottom lane']
inGameRoles['bot'] = inGameRoles['bottom lane']
inGameRoles['bottom'] = inGameRoles['bottom lane']
inGameRoles['carry'] = inGameRoles['bottom lane']
inGameRoles['farm'] = inGameRoles['bottom lane']
inGameRoles['mid laner'] = inGameRoles.middle
inGameRoles['mid'] = inGameRoles.middle
inGameRoles['top'] = inGameRoles['top lane']
inGameRoles['ds lane'] = inGameRoles['top lane']
inGameRoles['dsl'] = inGameRoles['top lane']
inGameRoles['dark slayer lane'] = inGameRoles['top lane']
inGameRoles['confront'] = inGameRoles['top lane']

return inGameRoles
