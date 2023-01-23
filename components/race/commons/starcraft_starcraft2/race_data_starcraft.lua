---
-- @Liquipedia
-- wiki=commons
-- page=Module:Race/Data/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local raceProps = {
	p = {
		bgClass = 'Protoss',
		index = 1,
		name = 'Protoss',
		pageName = 'Protoss',
		race = 'p',
	},
	t = {
		bgClass = 'Terran',
		index = 2,
		name = 'Terran',
		pageName = 'Terran',
		race = 't',
	},
	z = {
		bgClass = 'Zerg',
		index = 3,
		name = 'Zerg',
		pageName = 'Zerg',
		race = 'z',
	},
	r = {
		bgClass = 'Random',
		index = 4,
		name = 'Random',
		pageName = 'Random',
		race = 'r',
	},
	u = {
		index = 5,
		name = 'Unknown',
		race = 'u',
	},
}

return {
	raceProps = raceProps,
	defaultRace = 'u',
	races = {'p', 't', 'z', 'r', 'u'},
	knownRaces = {'p', 't', 'z', 'r'},
	coreRaces = {'p', 't', 'z'},
	aliases = {
		pt = 'p',
		pz = 'p',
		tp = 't',
		tz = 't',
		zp = 'z',
		zt = 'z',
	},
}
