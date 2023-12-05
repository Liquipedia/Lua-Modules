---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Faction/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local factionProps = {
	h = {
		bgClass = 'stormgate-human',
		index = 1,
		name = 'Human',
		pageName = 'The Human Vanguard',
		faction = 'h',
	},
	i = {
		bgClass = 'stormgate-ifernal',
		index = 2,
		name = 'Infernal',
		pageName = 'The Infernal Host',
		faction = 'i',
	},
	r = {
		bgClass = 'Random',
		index = 3,
		name = 'Random',
		pageName = 'Random',
		faction = 'r',
	},
	u = {
		index = 4,
		name = 'Unknown',
		faction = 'u',
	},
}

return {
	factionProps = factionProps,
	defaultFaction = 'u',
	factions = {'h', 'i', 'r', 'u'},
	knownFactions = {'h', 'i', 'r'},
	coreFactions = {'h', 'i'},
	aliases = {
		human = 'h',
		hu = 'h',
		vanguard = 'h',
		infernal = 'i',
		inf = 'i',
		host = 'i',
	},
}
