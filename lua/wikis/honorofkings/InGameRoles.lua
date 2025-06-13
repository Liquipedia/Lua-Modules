---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData[]
local inGameRoles = {
	['top'] = {category = 'Top Laners', display = 'Top Lane'},
	['bottom'] = {category = 'Bottom Laners', display = 'Bottom Laner'},
	['mid'] = {category = 'Mid Laners', display = 'Mid Laner'},
	['side lane'] = {category = 'Side Laners', display = 'Side Laner'},
	['jungler'] = {category = 'Junglers', display = 'Jungler'},
	['roamer'] = {category = 'Roamers', display = 'Roamer'},
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

return inGameRoles
