---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Race/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local raceProps = {
	h = {
		bgClass = '',--to be created
		index = 1,
		name = 'Human',
		pageName = 'Human',
		race = 'h',
	},
	o = {
		bgClass = '',--to be created
		index = 2,
		name = 'Orc',
		pageName = 'Orc',
		race = 'o',
	},
	n = {
		bgClass = '',--to be created
		index = 3,
		name = 'Nightelf',
		pageName = 'Nightelf',
		race = 'n',
	},
	u = {
		bgClass = '',--to be created
		index = 4,
		name = 'Undead',
		pageName = 'Undead',
		race = 'u',
	},
	r = {
		bgClass = '',--to be created
		index = 5,
		name = 'Random',
		pageName = 'Random',
		race = 'r',
	},
	m = {
		bgClass = '',--to be created
		index = 6,
		name = 'Multiple',
		pageName = 'Multiple',
		race = 'm',
	},
	a = {
		index = 7,
		name = 'Anonymous',
		race = 'a',
	},
}

return {
	raceProps = raceProps,
	defaultRace = 'a',
	races = {'h', 'o', 'n', 'u', 'r', 'a'},
	knownRaces = {'h', 'o', 'n', 'u', 'r'},
	coreRaces = {'h', 'o', 'n', 'u'},
	aliases = {},
}
