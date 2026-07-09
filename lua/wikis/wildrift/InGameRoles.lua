---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['baron'] = {category = 'Baron Lane players', display = 'Baron', sortOrder = 1},
	['jungle'] = {category = 'Jungle players', display = 'Jungle', sortOrder = 2},
	['mid'] = {category = 'Mid Lane players', display = 'Mid', sortOrder = 3},
	['dragon'] = {category = 'Dragon Lane players', display = 'Dragon', sortOrder = 4},
	['support'] = {category = 'Support players', display = 'Support', sortOrder = 5},
}

inGameRoles['top'] = inGameRoles.baron
inGameRoles['jgl'] = inGameRoles.jungle
inGameRoles['solomiddle'] = inGameRoles.mid
inGameRoles['carry'] = inGameRoles.dragon
inGameRoles['adc'] = inGameRoles.dragon
inGameRoles['bot'] = inGameRoles.dragon
inGameRoles['ad carry'] = inGameRoles.dragon
inGameRoles['sup'] = inGameRoles.support

return inGameRoles
