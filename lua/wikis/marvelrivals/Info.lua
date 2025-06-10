---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2024,
	wikiName = 'marvelrivals',
	name = 'Marvel Rivals',
	defaultGame = 'marvelrivals',
	games = {
		marvelrivals = {
			abbreviation = 'Marvel Rivals',
			name = 'Marvel Rivals',
			link = 'Marvel Rivals',
			logo = {
				darkMode = 'Marvel Rivals darkmode.png',
				lightMode = 'Marvel Rivals lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Marvel Rivals darkmode.png',
				lightMode = 'Marvel Rivals lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = true,
			hasSpecialTeam = false,
			allowManual = false,
		},
		match2 = {
			status = 2,
			matchWidth = 180,
		},
	},
	defaultRoundPrecision = 0,
}
