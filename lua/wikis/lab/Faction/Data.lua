---
-- @Liquipedia
-- page=Module:Faction/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

-- Heroes of Might and Magic

local HOMM_PREFIX = 'Heroesofmightandmagic/'
local H3_SUFFIX = '/Heroes of Might and Magic III'
local H4_SUFFIX = '/Heroes of Might and Magic IV'
local H5_SUFFIX = '/Heroes of Might and Magic V'
-- local H6_SUFFIX = '/Might & Magic: Heroes VI'
-- local H7_SUFFIX = '/Might & Magic: Heroes VII'
local HOE_SUFFIX = '/Heroes of Might and Magic: Olden Era'

local factionPropsH1 = {
	farm = {
		index = 1,
		name = 'Farm',
		pageName = HOMM_PREFIX .. 'Farm',
		faction = 'farm',
	},
	forest = {
		index = 2,
		name = 'Forest',
		pageName = HOMM_PREFIX .. 'Forest',
		faction = 'forest',
	},
	mountain = {
		index = 3,
		name = 'Mountain',
		pageName = HOMM_PREFIX .. 'Mountain',
		faction = 'mountain',
	},
	plains = {
		index = 4,
		name = 'Plains',
		pageName = HOMM_PREFIX .. 'Plains',
		faction = 'plains',
	},

	unknown = {
		index = 5,
		name = 'Unknown',
		faction = 'unknown',
	},
}

local factionPropsH2 = {
	barbarian = {
		index = 1,
		name = 'Barbarian',
		pageName = HOMM_PREFIX .. 'Barbarian',
		faction = 'barbarian',
	},
	knight = {
		index = 2,
		name = 'Knight',
		pageName = HOMM_PREFIX .. 'Knight',
		faction = 'knight',
	},
	necromancer = {
		index = 3,
		name = 'Necromancer',
		pageName = HOMM_PREFIX .. 'Necromancer',
		faction = 'necromancer',
	},
	sorceress = {
		index = 4,
		name = 'Sorceress',
		pageName = HOMM_PREFIX .. 'Sorceress',
		faction = 'sorceress',
	},
	warlock = {
		index = 5,
		name = 'Warlock',
		pageName = HOMM_PREFIX .. 'Warlock',
		faction = 'warlock',
	},
	wizard = {
		index = 6,
		name = 'Wizard',
		pageName = HOMM_PREFIX .. 'Wizard',
		faction = 'wizard',
	},

	unknown = {
		index = 7,
		name = 'Unknown',
		faction = 'unknown',
	},
}

local factionPropsH3 = {
	castle = {
		index = 1,
		name = 'Castle',
		pageName = HOMM_PREFIX .. 'Castle',
		faction = 'castle',
	},
	rampart = {
		index = 2,
		name = 'Rampart',
		pageName = HOMM_PREFIX .. 'Rampart',
		faction = 'rampart',
	},
	tower = {
		index = 3,
		name = 'Tower',
		pageName = HOMM_PREFIX .. 'Tower',
		faction = 'tower',
	},
	inferno = {
		index = 4,
		name = 'Inferno',
		pageName = HOMM_PREFIX .. 'Inferno' .. H3_SUFFIX,
		faction = 'inferno',
	},
	necropolis = {
		index = 5,
		name = 'Necropolis',
		pageName = HOMM_PREFIX .. 'Necropolis' .. H3_SUFFIX,
		faction = 'necropolis',
	},
	dungeon = {
		index = 6,
		name = 'Dungeon',
		pageName = HOMM_PREFIX .. 'Dungeon' .. H3_SUFFIX,
		faction = 'dungeon',
	},
	stronghold = {
		index = 7,
		name = 'Stronghold',
		pageName = HOMM_PREFIX .. 'Stronghold' .. H3_SUFFIX,
		faction = 'stronghold',
	},
	fortress = {
		index = 8,
		name = 'Fortress',
		pageName = HOMM_PREFIX .. 'Fortress' .. H3_SUFFIX,
		faction = 'fortress',
	},
	conflux = {
		index = 9,
		name = 'Conflux',
		pageName = HOMM_PREFIX .. 'Conflux',
		faction = 'conflux',
	},
	cove = {
		index = 10,
		name = 'Cove',
		pageName = HOMM_PREFIX .. 'Cove',
		faction = 'cove',
	},
	factory = {
		index = 11,
		name = 'Factory',
		pageName = HOMM_PREFIX .. 'Factory',
		faction = 'factory',
	},
	bulwark = {
		index = 12,
		name = 'Bulwark',
		pageName = HOMM_PREFIX .. 'Bulwark',
		faction = 'bulwark',
	},

	unknown = {
		index = 13,
		name = 'Unknown',
		faction = 'unknown',
	},
}

local factionPropsH4 = {
	haven = {
		index = 1,
		name = 'Haven',
		pageName = HOMM_PREFIX .. 'Haven' .. H4_SUFFIX,
		faction = 'haven',
	},
	stronghold = {
		index = 2,
		name = 'Stronghold',
		pageName = HOMM_PREFIX .. 'Stronghold' .. H4_SUFFIX,
		faction = 'stronghold',
	},
	academy = {
		index = 3,
		name = 'Academy',
		pageName = HOMM_PREFIX .. 'Academy' .. H4_SUFFIX,
		faction = 'academy',
	},
	preserve = {
		index = 4,
		name = 'Preserve',
		pageName = HOMM_PREFIX .. 'Preserve',
		faction = 'preserve',
	},
	necropolis = {
		index = 5,
		name = 'Necropolis',
		pageName = HOMM_PREFIX .. 'Necropolis' .. H4_SUFFIX,
		faction = 'necropolis',
	},
	asylum = {
		index = 6,
		name = 'Asylum',
		pageName = HOMM_PREFIX .. 'Asylum',
		faction = 'asylum',
	},

	unknown = {
		index = 7,
		name = 'Unknown',
		faction = 'unknown',
	},
}

local factionPropsH5 = {
	academy = {
		index = 1,
		name = 'Academy',
		pageName = HOMM_PREFIX .. 'Academy' .. H5_SUFFIX,
		faction = 'academy',
	},
	dungeon = {
		index = 2,
		name = 'Dungeon',
		pageName = HOMM_PREFIX .. 'Dungeon' .. H5_SUFFIX,
		faction = 'dungeon',
	},

	haven = {
		index = 3,
		name = 'Haven',
		pageName = HOMM_PREFIX .. 'Haven' .. H5_SUFFIX,
		faction = 'haven',
	},
	inferno = {
		index = 4,
		name = 'Inferno',
		pageName = HOMM_PREFIX .. 'Inferno' .. H5_SUFFIX,
		faction = 'inferno',
	},
	necropolis = {
		index = 5,
		name = 'Necropolis',
		pageName = HOMM_PREFIX .. 'Necropolis' .. H5_SUFFIX,
		faction = 'necropolis',
	},
	sylvan = {
		index = 6,
		name = 'Sylvan',
		pageName = HOMM_PREFIX .. 'Sylvan' .. H5_SUFFIX,
		faction = 'sylvan',
	},

	fortress = {
		index = 7,
		name = 'Fortress',
		pageName = HOMM_PREFIX .. 'Fortress' .. H5_SUFFIX,
		faction = 'fortress',
	},
	stronghold = {
		index = 8,
		name = 'Stronghold',
		pageName = HOMM_PREFIX .. 'Stronghold' .. H5_SUFFIX,
		faction = 'stronghold',
	},

	unknown = {
		index = 9,
		name = 'Unknown',
		faction = 'unknown',
	},
}

local factionPropsHOE = {
	temple = {
		index = 1,
		name = 'Temple',
		pageName = HOMM_PREFIX .. 'Temple',
		faction = 'temple',
	},
	necropolis = {
		index = 2,
		name = 'Necropolis',
		pageName = HOMM_PREFIX .. 'Necropolis' .. HOE_SUFFIX,
		faction = 'necropolis',
	},

	sylvan = {
		index = 3,
		name = 'Sylvan',
		pageName = HOMM_PREFIX .. 'Sylvan' .. HOE_SUFFIX,
		faction = 'sylvan',
	},
	dungeon = {
		index = 4,
		name = 'Dungeon',
		pageName = HOMM_PREFIX .. 'Dungeon' .. HOE_SUFFIX,
		faction = 'dungeon',
	},
	hive = {
		index = 5,
		name = 'Hive',
		pageName = HOMM_PREFIX .. 'Hive',
		faction = 'hive',
	},
	schism = {
		index = 6,
		name = 'Schism',
		pageName = HOMM_PREFIX .. 'Schism',
		faction = 'schism',
	},

	unknown = {
		index = 7,
		name = 'Unknown',
		faction = 'unknown',
	},
}

return {
	factionProps = {
		-- Heroes of Might and Magic
		h1 = factionPropsH1,
		h2 = factionPropsH2,
		h3 = factionPropsH3,
		h4 = factionPropsH4,
		h5 = factionPropsH5,
		hoe = factionPropsHOE,
	},
	defaultFaction = 'unknown',
	factions = {
		-- Heroes of Might and Magic
		h1 = Array.extractKeys(factionPropsH1),
		h2 = Array.extractKeys(factionPropsH2),
		h3 = Array.extractKeys(factionPropsH3),
		h4 = Array.extractKeys(factionPropsH4),
		h5 = Array.extractKeys(factionPropsH5),
		hoe = Array.extractKeys(factionPropsHOE),
	},
	aliases = {
		-- Heroes of Might and Magic
		h1 = {
			far = 'farm',
			['for'] = 'forest',
			mou = 'mountain',
			pla = 'plains',
		},
		h2 = {
			bar = 'barbarian',
			kni = 'knight',
			nec = 'necromancer',
			sor = 'sorceress',
			war = 'warlock',
			wiz = 'wizard',
		},
		h3 = {
			cas = 'castle',
			ram = 'rampart',
			tow = 'tower',
			inf = 'inferno',
			nec = 'necropolis',
			necro = 'necropolis',
			dun = 'dungeon',
			str = 'stronghold',
			strong = 'stronghold',
			['for'] = 'fortress',
			fort = 'fortress',
			con = 'conflux',
			flux = 'conflux',
			cov = 'cove',
			fac = 'factory',
			bul = 'bulwark',
		},
		h4 = {
			hav = 'haven',
			str = 'stronghold',
			strong = 'stronghold',
			aca = 'academy',
			pre = 'preserve',
			nec = 'necropolis',
			necro = 'necropolis',
			asy = 'asylum',
		},
		h5 = {
			aca = 'academy',
			dun = 'dungeon',
			hav = 'haven',
			inf = 'inferno',
			nec = 'necropolis',
			necro = 'necropolis',
			syl = 'sylvan',
			['for'] = 'fortress',
			fort = 'fortress',
			str = 'stronghold',
			strong = 'stronghold',
		},
		hoe = {
			tem = 'temple',
			nec = 'necropolis'',
			necro = 'necropolis',
			syl = 'sylvan',
			dun = 'dungeon',
			hiv = 'hive',
			sch = 'schism',
		}
	},
}
