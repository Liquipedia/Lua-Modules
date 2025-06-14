---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData[]
local inGameRoles = {
	['baron'] = {category = 'Baron Lane players', display = 'Baron'},
	['support'] = {category = 'Support players', display = 'Support'},
	['jungle'] = {category = 'Jungle players', display = 'Jungle'},
	['mid'] = {category = 'Mid Lane players', display = 'Mid'},
	['dragon'] = {category = 'Dragon Lane players', display = 'Dragon'},
}

inGameRoles['jgl'] = inGameRoles.jungle
inGameRoles['solomiddle'] = inGameRoles.mid
inGameRoles['carry'] = inGameRoles.dragon
inGameRoles['adc'] = inGameRoles.dragon
inGameRoles['bot'] = inGameRoles.dragon
inGameRoles['ad carry'] = inGameRoles.dragon
inGameRoles['sup'] = inGameRoles.support

return inGameRoles
