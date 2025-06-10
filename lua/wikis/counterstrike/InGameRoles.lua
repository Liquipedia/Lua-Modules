---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData
local inGameRoles = {
	['awper'] = {category = 'AWPers', display = 'AWPer'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leader'},
	['lurker'] = {category = 'Riflers', display = 'Rifler'},
	['support'] = {category = 'Riflers', display = 'Rifler'},
	['entry'] = {category = 'Riflers', display = 'Rifler'},
	['rifler'] = {category = 'Riflers', display = 'Rifler'},
}

inGameRoles['awp'] = inGameRoles.awper
inGameRoles['lurk'] = inGameRoles.lurker
inGameRoles['entryfragger'] = inGameRoles.entry
inGameRoles['rifle'] = inGameRoles.rifler

return inGameRoles
