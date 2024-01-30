---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Faction/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = mw.loadData('Module:Info')

local factionProps = {
	v = {
		bgClass = 'stormgate-vanguard',
		index = 1,
		name = 'Vanguard',
		pageName = 'Human Vanguard',
		faction = 'v',
	},
	i = {
		bgClass = 'stormgate-infernal',
		index = 2,
		name = 'Infernal',
		pageName = 'Infernal Host',
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
	defaultGame = Info.defaultGame,
	factionProps = {
		[Info.defaultGame] = factionProps,
	},
	defaultFaction = 'u',
	factions = {
		[Info.defaultGame] = {'v', 'i', 'r', 'u'},
	},
	knownFactions = {'v', 'i', 'r'},
	coreFactions = {'v', 'i'},
	aliases = {
		[Info.defaultGame] = {
			human = 'v',
			host = 'i',
		},
	}
}
