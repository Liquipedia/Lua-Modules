---
-- @Liquipedia
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData
local inGameRoles = {
	['carry'] = {category = 'Carry players', display = 'Carry'},
	['mid'] = {category = 'Solo middle players', display = 'Solo Middle'},
	['offlane'] = {category = 'Offlaners', display = 'Offlaner'},
	['support'] = {category = 'Support players', display = 'Support'},
	['captain'] = {category = 'Captains', display = 'Captain'},
}

inGameRoles['solo middle'] = inGameRoles.mid
inGameRoles['solomiddle'] = inGameRoles.mid
inGameRoles['offlaner'] = inGameRoles.offlane

return inGameRoles
