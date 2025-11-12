---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, PersonRoleData>
local inGameRoles = {
	['awper'] = {category = 'AWPers', display = 'AWPer'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leader'},
	['lurker'] = {category = 'Lurkers', display = 'Lurker'},
	['support'] = {category = 'Support players', display = 'Support'},
	['entry'] = {category = 'Entry fraggers', display = 'Entry'},
	['rifler'] = {category = 'Riflers', display = 'Rifler'},
}

inGameRoles['awp'] = inGameRoles.awper
inGameRoles['lurk'] = inGameRoles.lurker
inGameRoles['entryfragger'] = inGameRoles.entry
inGameRoles['rifle'] = inGameRoles.rifler

return inGameRoles
