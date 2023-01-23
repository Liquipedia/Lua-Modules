---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Race/IconData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local byRace = {
	p = {
		icon = 'File:Protoss race icon.png',
	},
	t = {
		icon = 'File:Terran race icon.png',
	},
	z = {
		icon = 'File:Zerg race icon.png',
	},
	r = {
		icon = 'File:Random race icon.png',
	},
	u = {
		icon = 'File:Space filler race.png',
	},
}

local randomIcons = {
	['r(p)'] = 'File:Random Protoss race icon.png',
	['r(t)'] = 'File:Random Terran race icon.png',
	['r(z)'] = 'File:Random Zerg race icon.png',
}

return {byRace = byRace, randomIcons = randomIcons}
