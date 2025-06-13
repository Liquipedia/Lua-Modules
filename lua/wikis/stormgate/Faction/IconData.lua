---
-- @Liquipedia
-- page=Module:Faction/IconData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = mw.loadData('Module:Info')

local byFaction = {
	v = {
		icon = 'File:Stormgate Human Vanguard default allmode.png',
	},
	i = {
		icon = 'File:Stormgate Infernal Host default allmode.png',
	},
	c = {
		icon = 'File:Stormgate Celestial Armada default allmode.png',
	},
	r = {
		icon = 'File:Random race icon.png',
	},
	n = {
		icon = 'File:Space filler race.png',
	},
	u = {
		icon = 'File:Space filler race.png',
	},
}

return {byFaction = {[Info.defaultGame] = byFaction}, randomIcons = {}}
