---
-- @Liquipedia
-- wiki=dota2
-- page=Module:InGameRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local inGameRoles = {
	['carry'] = {category = 'Carry players', variable = 'Carry', isplayer = true},
	['mid'] = {category = 'Solo middle players', variable = 'Solo Middle', isplayer = true},
	['offlane'] = {category = 'Offlaners', variable = 'Offlaner', isplayer = true},
	['support'] = {category = 'Support players', variable = 'Support', isplayer = true},
	['captain'] = {category = 'Captains', variable = 'Captain', isplayer = true},
}

inGameRoles['solo middle'] = inGameRoles.mid
inGameRoles['solomiddle'] = inGameRoles.mid
inGameRoles.offlaner = inGameRoles.offlane

return inGameRoles
