---
-- @Liquipedia
-- page=Module:Faction/IconData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = mw.loadData('Module:Info')

local byFaction = {
	h = {
		icon = 'File:Human icon small.png',
	},
	o = {
		icon = 'File:Orc icon small.png',
	},
	n = {
		icon = 'File:Nightelf icon small.png',
	},
	u = {
		icon = 'File:Undead icon small.png',
	},
	r = {
		icon = 'File:Random race icon.png',
	},
	m = {
		icon = 'File:Multiple icon small.png',
	},
	a = {
		icon = 'File:Space filler race.png',
	},
}

return {byFaction = {[Info.defaultGame] = byFaction}, randomIcons = {}}
