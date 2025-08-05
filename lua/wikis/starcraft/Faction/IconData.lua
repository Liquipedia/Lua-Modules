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
		icon = 'File:Picon small bw.png',
	},
	t = {
		altIcon = 'File:TerranIcon.png',
		icon = 'File:Ticon small bw.png',
	},
	z = {
		altIcon = 'File:ZergIcon.png',
		icon = 'File:Zicon small bw.png',
	},
	r = {
		altIcon = 'File:RaceIcon Random.png',
		icon = 'File:Ricon small bw.png',
	},
	u = {
		icon = 'File:Space filler race.png',
	},
}

local randomIcons = {
	['r(p)'] = 'File:R(P)icon small bw.png',
	['r(t)'] = 'File:R(T)icon small bw.png',
	['r(z)'] = 'File:R(Z)icon small bw.png',
}

return {byFaction = {[Info.defaultGame] = byFaction}, randomIcons = randomIcons}
