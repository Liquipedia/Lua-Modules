---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1998,
	wikiName = 'starcraft',
	name = 'Brood War',
	defaultGame = 'bw',
	games = {
		bw = {
			abbreviation = 'BW',
			name = 'Brood War',
			link = 'Brood War',
			logo = {
				darkMode = 'StarCraft default allmode.png',
				lightMode = 'StarCraft default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'StarCraft default allmode.png',
				lightMode = 'StarCraft default allmode.png',
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
			status = 1,
			matchWidthMobile = 120,
			matchWidth = 170,
		},
	},
	maximumNumberOfPlayersInPlacements = 35,
	opponentLibrary = 'Opponent/Starcraft',
	opponentDisplayLibrary = 'OpponentDisplay/Starcraft',
}
