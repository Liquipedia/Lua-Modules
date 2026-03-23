---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, RoleBaseData>
local inGameRoles = {
	['support'] = {category = 'Support players', display = 'Support'},
	['rusher'] = {category = 'Rusher', display = 'Rusher'},
	['sniper'] = {category = 'Snipers', display = 'Snipers'},
	['bomber'] = {category = 'Bomber', display = 'Bomber'},
	['igl'] = {category = 'In-game leaders', display = 'In-game leaders'},
	['captain'] = {category = 'Captain', display = 'Captain'},
}

inGameRoles['granader'] = inGameRoles.bomber

return inGameRoles
