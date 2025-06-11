---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData
local inGameRoles = {
	['entry'] = {category = 'Entry fraggers', display = 'Entry fragger'},
	['support'] = {category = 'Support players', display = 'Support'},
	['flex'] = {category = 'Flex players', display = 'Flex'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leader'},
}

inGameRoles['entryfragger'] = inGameRoles['entry']

return inGameRoles
