---
-- @Liquipedia
-- page=Module:Faction/IconData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})

local byFaction = {
	p = {
		altIcon = 'File:ProtossIcon.png',
		icon = 'File:Protoss race icon.png',
	},
	t = {
		altIcon = 'File:TerranIcon.png',
		icon = 'File:Terran race icon.png',
	},
	z = {
		altIcon = 'File:ZergIcon.png',
		icon = 'File:Zerg race icon.png',
	},
	r = {
		altIcon = 'File:RaceIcon Random.png',
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

return {byFaction = {[Info.defaultGame] = byFaction}, randomIcons = randomIcons}
