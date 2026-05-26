---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2018,
	wikiName = 'pubgmobile',
	name = 'PUBG Mobile',
	defaultGame = 'pubgm',
	games = {
		pubgm = {
			abbreviation = 'PUBGM',
			name = 'PUBG Mobile',
			link = 'PUBG Mobile',
			logo = {
				darkMode = 'PUBG Mobile default darkmode.png',
				lightMode = 'PUBG Mobile default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'PUBG Default logo.png',
				lightMode = 'PUBG Default logo.png',
			},
		},
		gfp = {
			abbreviation = 'GFP',
			name = 'Game for Peace',
			link = 'Game for Peace',
			logo = {
				darkMode = 'Game for Peace alt darkmode.png',
				lightMode = 'Game for Peace alt lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'PUBG Default logo.png',
				lightMode = 'PUBG Default logo.png',
			},
		},
		bgmi = {
			abbreviation = 'BGMI',
			name = 'Battlegrounds Mobile India',
			link = 'Battlegrounds Mobile India',
			logo = {
				darkMode = 'Battlegrounds Mobile India 2022 darkmode.png',
				lightMode = 'Battlegrounds Mobile India 2022 lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'PUBG Default logo.png',
				lightMode = 'PUBG Default logo.png',
			},
		},
		ns = {
			abbreviation = 'NS',
			name = 'NEW STATE MOBILE',
			link = 'NEW STATE MOBILE',
			logo = {
				darkMode = 'NEW STATE MOBILE allmode.png',
				lightMode = 'NEW STATE MOBILE allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'NEW STATE MOBILE default allmode.png',
				lightMode = 'NEW STATE MOBILE default allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 1,
		},
		transfers = {
			showTeamName = true,
		},
		infoboxPlayer = {
			autoTeam = true,
			automatedHistory = {
				mode = 'merge',
				hasHeaderAndRefs = true,
			},
		},
		participants = {
			defaultPlayerNumber = 4,
		},
	},
	defaultRoundPrecision = 0,
}
