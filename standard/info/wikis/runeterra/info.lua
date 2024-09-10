---
-- @Liquipedia
-- wiki=runeterra
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2020,
	wikiName = 'runeterra',
	name = 'Legends of Runeterra',
	defaultGame = 'runeterra',
	games = {
		runeterra = {
			abbreviation = 'Runeterra',
			name = 'Legends of Runeterra',
			link = 'Legends of Runeterra',
			logo = {
				darkMode = 'Legends of Runeterra logo.png',
				lightMode = 'Legends of Runeterra logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Legends of Runeterra logo.png',
				lightMode = 'Legends of Runeterra logo.png',
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
		},
	},
}
