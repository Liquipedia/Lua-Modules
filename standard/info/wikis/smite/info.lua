---
-- @Liquipedia
-- wiki=smite
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2013,
	wikiName = 'smite',
	name = 'SMITE',
	defaultGame = 'smite',
	games = {
		smite = {
			abbreviation = 'S1',
			name = 'SMITE',
			link = 'SMITE',
			logo = {
				darkMode = 'SMITE default darkmode.png',
				lightMode = 'SMITE default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'SMITE default darkmode.png',
				lightMode = 'SMITE default lightmode.png',
			},
		},
		smite2 = {
			abbreviation = 'S2',
			name = 'SMITE 2',
			link = 'SMITE 2',
			logo = {
				darkMode = 'SMITE 2 default allmode.png',
				lightMode = 'SMITE 2 default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'SMITE default darkmode.png',
				lightMode = 'SMITE default lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = true,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 0,
		},
	},
}
