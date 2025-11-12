---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['top'] = {category = 'Top Lane players', display = 'Top', sortOrder = 1, doNotShowInHistory = true},
	['support'] = {category = 'Support players', display = 'Support', sortOrder = 2, doNotShowInHistory = true},
	['jungle'] = {category = 'Jungle players', display = 'Jungle', sortOrder = 3, doNotShowInHistory = true},
	['mid'] = {category = 'Mid Lane players', display = 'Mid', sortOrder = 4, doNotShowInHistory = true},
	['bottom'] = {category = 'Bot Lane players', display = 'Bot', sortOrder = 5, doNotShowInHistory = true},
}

inGameRoles['jg'] = inGameRoles.jungle
inGameRoles['jgl'] = inGameRoles.jungle
inGameRoles['jun'] = inGameRoles.jungle
inGameRoles['middle'] = inGameRoles.mid
inGameRoles['solomiddle'] = inGameRoles.mid
inGameRoles['carry'] = inGameRoles.bottom
inGameRoles['adc'] = inGameRoles.bottom
inGameRoles['bot'] = inGameRoles.bottom
inGameRoles['ad carry'] = inGameRoles.bottom
inGameRoles['sup'] = inGameRoles.support

return inGameRoles
