---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData[]
local inGameRoles = {
	['top'] = {category = 'Top Lane players', display = 'Top'},
	['support'] = {category = 'Support players', display = 'Support'},
	['jungle'] = {category = 'Jungle players', display = 'Jungle'},
	['mid'] = {category = 'Mid Lane players', display = 'Mid'},
	['bottom'] = {category = 'Bot Lane players', display = 'Bot'},
}

inGameRoles['jgl'] = inGameRoles.jungle
inGameRoles['solomiddle'] = inGameRoles.mid
inGameRoles['carry'] = inGameRoles.bottom
inGameRoles['adc'] = inGameRoles.bottom
inGameRoles['bot'] = inGameRoles.bottom
inGameRoles['ad carry'] = inGameRoles.bottom
inGameRoles['sup'] = inGameRoles.support

return inGameRoles
