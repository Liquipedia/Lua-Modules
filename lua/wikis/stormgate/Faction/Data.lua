---
-- @Liquipedia
-- page=Module:Faction/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Info = Lua.import('Module:Info', {loadData = true})

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
	c = {
		bgClass = 'stormgate-celestial',
		index = 3,
		name = 'Celestial',
		pageName = 'Celestial Armada',
		faction = 'c',
	},
	r = {
		bgClass = 'Random',
		index = 4,
		name = 'Random',
		pageName = 'Random',
		faction = 'r',
	},
	n = {
		index = 5,
		name = 'Neutral',
		faction = 'n',
	},
	u = {
		index = 6,
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
		[Info.defaultGame] = {'v', 'i', 'c', 'r', 'u'},
	},
	knownFactions = {'v', 'i', 'c', 'r'},
	coreFactions = {'v', 'i', 'c'},
	aliases = {
		[Info.defaultGame] = {
			human = 'v',
			van = 'v',
			host = 'i',
			inf = 'i',
			cel = 'c',
		},
	}
}
