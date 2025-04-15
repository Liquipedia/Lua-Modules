---
-- @Liquipedia
-- wiki=honorofkings
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local inGameRoles = {
	['igl'] = {category = 'In-game leaders', display = 'In-game Leader'},
	['top'] = {category = 'Top Laners', display = 'Top Lane'},
	['bottom'] = {category = 'Bottom Laners', display = 'Bottom Lane'},
	['mid'] = {category = 'Mid Laners', display = 'Mid Lane'},
	['side lane'] = {category = 'Side Laners', display = 'Side Lane'},
	['jungler'] = {category = 'Junglers', display = 'Jungler'},
	['support'] = {category = 'Supporters', display = 'Roamer'},
}

inGameRoles.jgl = inGameRoles.jungler
inGameRoles.jungle = inGameRoles.jungler
inGameRoles.roam = inGameRoles.support
inGameRoles.sup = inGameRoles.support
inGameRoles['ad lane'] = inGameRoles.bottom
inGameRoles['ad carry'] = inGameRoles.bottom
inGameRoles.adl = inGameRoles.bottom
inGameRoles.adc = inGameRoles.bottom
inGameRoles.bot = inGameRoles.bottom
inGameRoles.carry = inGameRoles.bottom
inGameRoles['mid laner'] = inGameRoles.mid
inGameRoles['ds lane'] = inGameRoles.top
inGameRoles.dsl = inGameRoles.top

return inGameRoles
