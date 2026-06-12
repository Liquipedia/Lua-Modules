---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['scout'] = {category = 'Scouts', display = 'Scout'},
	['soldier'] = {category = 'Soldiers', display = 'Soldier'},
	['pocket'] = {category = 'Pocket Soldiers', display = 'Pocket Soldier'},
	['pyro'] = {category = 'Pyros', display = 'Pyro'},
	['demoman'] = {category = 'Demomen', display = 'Demoman'},
	['heavy'] = {category = 'Heavies', display = 'Heavy'},
	['engineer'] = {category = 'Engineers', display = 'Engineer'},
	['medic'] = {category = 'Medics', display = 'Medic'},
	['sniper'] = {category = 'Snipers', display = 'Sniper'},
	['spy'] = {category = 'Spies', display = 'Spy'},
}

inGameRoles['solly'] = inGameRoles.soldier
inGameRoles['roamer'] = inGameRoles.soldier
inGameRoles['pocketsoldier'] = inGameRoles.pocket
inGameRoles['pocketsolly'] = inGameRoles.pocket
inGameRoles['demo'] = inGameRoles.demoman
inGameRoles['engi'] = inGameRoles.engineer
inGameRoles['med'] = inGameRoles.medic

return inGameRoles
