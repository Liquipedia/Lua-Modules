---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1997,
	wikiName = 'ageofempires',
	name = 'Age of Empires',
	defaultGame = 'Age of Empires II',

	games = {
		['Age of Empires I'] = {
			abbreviation = 'AoE1',
			name = 'Age of Empires I',
			link = 'Age of Empires I',
			logo = {
				darkMode = 'AoE1 Icon.png',
				lightMode = 'AoE1 Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Age of Empires default allmode.png',
				lightMode = 'Age of Empires default allmode.png',
			},
			order = 1,
		},
		['Age of Empires II'] = {
			abbreviation = 'AoE2',
			name = 'Age of Empires II',
			link = 'Age of Empires II',
			logo = {
				darkMode = 'AoE2 Icon.png',
				lightMode = 'AoE2 Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Age of Empires default allmode.png',
				lightMode = 'Age of Empires default allmode.png',
			},
			order = 2,
		},
		['Age of Empires III'] = {
			abbreviation = 'AoE3',
			name = 'Age of Empires III',
			link = 'Age of Empires III',
			logo = {
				darkMode = 'AoE3 Icon.png',
				lightMode = 'AoE3 Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Age of Empires default allmode.png',
				lightMode = 'Age of Empires default allmode.png',
			},
			order = 3,
		},
		['Age of Empires IV'] = {
			abbreviation = 'AoE4',
			name = 'Age of Empires IV',
			link = 'Age of Empires IV',
			logo = {
				darkMode = 'AoE4 Icon.png',
				lightMode = 'AoE4 Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Age of Empires default allmode.png',
				lightMode = 'Age of Empires default allmode.png',
			},
			order = 4,
		},
		['Age of Mythology'] = {
			abbreviation = 'AoM',
			name = 'Age of Mythology',
			link = 'Age of Mythology',
			logo = {
				darkMode = 'AoM Icon.png',
				lightMode = 'AoM Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Age of Empires default allmode.png',
				lightMode = 'Age of Empires default allmode.png',
			},
			order = 5,
		},
		['Age of Empires Online'] = {
			abbreviation = 'AoEO',
			name = 'Age of Empires Online',
			link = 'Age of Empires Online',
			logo = {
				darkMode = 'AoEO Icon.png',
				lightMode = 'AoEO Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Age of Empires default allmode.png',
				lightMode = 'Age of Empires default allmode.png',
			},
			order = 6,
		},
	},

	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 2,
			matchWidthMobile = 110,
		},
		infoboxPlayer = {
			autoTeam = true,
			automatedHistory = {
				mode = 'cleanup',
			},
		},
	},
}
