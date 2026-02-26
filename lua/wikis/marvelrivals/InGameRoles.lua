---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['duelist'] = {category = 'Duelist Players', display = 'Duelist', sortOrder = 1},
	['flex'] = {category = 'Flex Players', display = 'Flex', sortOrder = 4},
	['strategist'] = {category = 'Strategist Players', display = 'Strategist', sortOrder = 3},
	['vanguard'] = {category = 'Vanguard Players', display = 'Vanguard', sortOrder = 2},
}

inGameRoles['dps'] = inGameRoles.duelist
inGameRoles['tank'] = inGameRoles.vanguard
inGameRoles['sup'] = inGameRoles.strategist

return inGameRoles
