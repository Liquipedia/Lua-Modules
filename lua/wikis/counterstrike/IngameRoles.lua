---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local inGameRoles = {
	['awper'] = {category = 'AWPers', display = 'AWPer', store = 'awp'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leader', store = 'igl'},
	['lurker'] = {category = 'Riflers', display = 'Rifler', category2 = 'Lurkers', display2 = 'lurker'},
	['support'] = {category = 'Riflers', display = 'Rifler', category2 = 'Support players', display2 = 'support'},
	['entry'] = {category = 'Riflers', display = 'Rifler', category2 = 'Entry fraggers', display2 = 'entry fragger'},
	['rifler'] = {category = 'Riflers', display = 'Rifler'},
}

inGameRoles.awp = inGameRoles.awper
inGameRoles.lurk = inGameRoles.lurker
inGameRoles.entryfragger = inGameRoles.entry
inGameRoles.rifle = inGameRoles.rifler

return inGameRoles
