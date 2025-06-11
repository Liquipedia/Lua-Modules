---
-- @Liquipedia
-- page=Module:Faction/Data/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = mw.loadData('Module:Info')

local factionProps = {
	p = {
		bgClass = 'Protoss',
		index = 1,
		name = 'Protoss',
		pageName = 'Protoss',
		faction = 'p',
	},
	t = {
		bgClass = 'Terran',
		index = 2,
		name = 'Terran',
		pageName = 'Terran',
		faction = 't',
	},
	z = {
		bgClass = 'Zerg',
		index = 3,
		name = 'Zerg',
		pageName = 'Zerg',
		faction = 'z',
	},
	r = {
		bgClass = 'Random',
		index = 4,
		name = 'Random',
		pageName = 'Random',
		faction = 'r',
	},
	u = {
		index = 5,
		name = 'Unknown',
		faction = 'u',
	},
}

return {
	defaultGame = Info.defaultGame,
	factionProps = {
		[Info.defaultGame] = factionProps
	},
	defaultFaction = 'u',
	factions = {
		[Info.defaultGame] = {'p', 't', 'z', 'r', 'u'},
	},
	knownFactions = {'p', 't', 'z', 'r'},
	coreFactions = {'p', 't', 'z'},
	aliases = {
		[Info.defaultGame] = {
			pt = 'p',
			pz = 'p',
			tp = 't',
			tz = 't',
			zp = 'z',
			zt = 'z',
		},
	},
}
