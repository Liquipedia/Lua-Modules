---
-- @Liquipedia
-- wiki=zula
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2015,
	wikiName = 'zula',
	name = 'Zula',
	defaultGame = 'zula',
	games = {
		zula = {
			abbreviation = 'Zula',
			name = 'Zula',
			link = 'Main Page',
			logo = {
				darkMode = 'Zula Global default allmode.png',
				lightMode = 'Zula Global default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Zula Global default allmode.png',
				lightMode = 'Zula Global default allmode.png',
			},
		},
		global = {
			abbreviation = 'Global',
			name = 'Zula Global',
			link = 'Zula Global',
			logo = {
				darkMode = 'Zula Global default allmode.png',
				lightMode = 'Zula Global default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Zula Global allmode.png',
				lightMode = 'Zula Global allmode.png',
			},
		},
		oyun = {
			abbreviation = 'Oyun',
			name = 'Zula Oyun',
			link = 'Zula Oyun',
			logo = {
				darkMode = 'Zula Oyun allmode.png',
				lightMode = 'Zula Oyun allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Zula Oyun allmode.png',
				lightMode = 'Zula Oyun allmode.png',
			},
		},
		europe = {
			abbreviation = 'Europe',
			name = 'Zula Europe',
			link = 'Zula Europe',
			logo = {
				darkMode = 'Zula Oyun allmode.png',
				lightMode = 'Zula Oyun allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Zula Oyun allmode.png',
				lightMode = 'Zula Oyun allmode.png',
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
			status = 2,
			matchWidthMobile = 110,
			matchWidth = 200,
		},
	},
}
