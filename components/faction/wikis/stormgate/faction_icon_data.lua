---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Faction/IconData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = mw.loadData('Module:Info')

local byFaction = {
	v = {
		icon = 'File:Stormgate_Human_Vanguard_default_allmode.png',
	},
	i = {
		icon = 'File:Stormgate_Infernal_Host_default_allmode.png',
	},
	r = {
		icon = 'File:Random race icon.png',
	},
	u = {
		icon = 'File:Space filler race.png',
	},
}

return {byFaction = {[Info.defaultGame] = byFaction}, randomIcons = {}}
