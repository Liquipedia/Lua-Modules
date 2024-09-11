---
-- @Liquipedia
-- wiki=omegastrikers
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2022,
	wikiName = 'omegastrikers',
	name = 'Omega Strikers',
	defaultGame = 'omegastrikers',
	games = {
		omegastrikers = {
			abbreviation = 'OS',
			name = 'Omega Strikers',
			link = 'Main Page',
			logo = {
				darkMode = 'Omega Strikers default allmode.png',
				lightMode = 'Omega Strikers default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Omega Strikers default allmode.png',
				lightMode = 'Omega Strikers default allmode.png',
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
			status = 0,
			matchWidth = 180,
		},
	},
}
