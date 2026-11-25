---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['entry'] = {category = 'Entry fraggers', display = 'Entry fragger'},
	['support'] = {category = 'Support players', display = 'Support'},
	['flex'] = {category = 'Flex players', display = 'Flex'},
}

inGameRoles['entryfragger'] = inGameRoles['entry']

return inGameRoles
