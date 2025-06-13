---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData[]
local inGameRoles = {
	['igl'] = {category = 'In-game leaders', display = 'In-game Leader'},
	['frontline'] = {category = 'Frontline', display = 'Frontline'},
	['backline'] = {category = 'Backline', display = 'Backline'},
	['support'] = {category = 'Support', display = 'Support'},
	['flex'] = {category = 'Flex', display = 'Flex'},
}

inGameRoles['front'] = inGameRoles['frontline']
inGameRoles['sup'] = inGameRoles['support']
inGameRoles['back'] = inGameRoles['backline']

return inGameRoles
