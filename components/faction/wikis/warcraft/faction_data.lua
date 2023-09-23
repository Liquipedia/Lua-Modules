---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Faction/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local factionProps = {
	h = {
		bgClass = 'warcraft-human',
		index = 1,
		name = 'Human',
		pageName = 'Human',
		faction = 'h',
	},
	o = {
		bgClass = 'warcraft-orc',
		index = 2,
		name = 'Orc',
		pageName = 'Orc',
		faction = 'o',
	},
	n = {
		bgClass = 'warcraft-nightelf',
		index = 3,
		name = 'Nightelf',
		pageName = 'Nightelf',
		faction = 'n',
	},
	u = {
		bgClass = 'warcraft-undead',
		index = 4,
		name = 'Undead',
		pageName = 'Undead',
		faction = 'u',
	},
	r = {
		bgClass = 'Random',
		index = 5,
		name = 'Random',
		pageName = 'Random',
		faction = 'r',
	},
	m = {
		bgClass = 'warcraft-multirace',
		index = 6,
		name = 'Multiple',
		pageName = 'Multiple',
		faction = 'm',
	},
	a = {
		index = 7,
		name = 'Anonymous',
		faction = 'a',
	},
}

return {
	factionProps = factionProps,
	defaultFaction = 'a',
	factions = {'h', 'o', 'n', 'u', 'r', 'a'},
	knownFactions = {'h', 'o', 'n', 'u', 'r'},
	coreFactions = {'h', 'o', 'n', 'u'},
	aliases = {['night elf'] = 'n'},
}
