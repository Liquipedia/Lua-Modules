---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['warrior'] = {category = 'Warriors', display = 'Warrior'},
	['melee'] = {category = 'Melee Assassins', display = 'Melee Assassin'},
	['ranged'] = {category = 'Ranged Assassins', display = 'Ranged Assassin'},
	['flex'] = {category = 'Flex players', display = 'Flex'},
	['support'] = {category = 'Support players', display = 'Support'},
	['healer'] = {category = 'Healers', display = 'Healer'},
	['offlane'] = {category = 'Offlaners', display = 'Offlaner'},
}

inGameRoles['war'] = inGameRoles.warrior
inGameRoles['tank'] = inGameRoles.warrior
inGameRoles['mel'] = inGameRoles.melee
inGameRoles['ran'] = inGameRoles.ranged
inGameRoles['sup'] = inGameRoles.support
inGameRoles['heal'] = inGameRoles.healer
inGameRoles['off'] = inGameRoles.offlane
inGameRoles['solo'] = inGameRoles.offlane

return inGameRoles
