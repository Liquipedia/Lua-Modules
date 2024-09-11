---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2010,
	wikiName = 'starcraft2',
	name = 'StarCraft II',
	defaultGame = 'wol',
	games = {
		wol = {
			abbreviation = 'WoL',
			name = 'Wings of Liberty',
			link = 'Wings of Liberty',
			logo = {
				darkMode = 'StarCraft 2 Default logo.png',
				lightMode = 'StarCraft 2 Default logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'StarCraft 2 Default logo.png',
				lightMode = 'StarCraft 2 Default logo.png',
			},
		},
		hots = {
			abbreviation = 'HotS',
			name = 'Heart of the Swarm',
			link = 'Heart of the Swarm',
			logo = {
				darkMode = 'StarCraft 2 Default logo.png',
				lightMode = 'StarCraft 2 Default logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'StarCraft 2 Default logo.png',
				lightMode = 'StarCraft 2 Default logo.png',
			},
		},
		lotv = {
			abbreviation = 'LotV',
			name = 'Legacy of the Void',
			link = 'Legacy of the Void',
			logo = {
				darkMode = 'StarCraft 2 Default logo.png',
				lightMode = 'StarCraft 2 Default logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'StarCraft 2 Default logo.png',
				lightMode = 'StarCraft 2 Default logo.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = true,
			allowManual = true,
		},
		match2 = {
			status = 2,
			matchWidthMobile = 110,
			matchWidth = 150,
		},
	},
	opponentLibrary = 'Opponent/Starcraft',
	opponentDisplayLibrary = 'OpponentDisplay/Starcraft',
}
