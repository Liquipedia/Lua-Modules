---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2025,
	wikiName = 'rematch',
	name = 'Rematch',
	defaultGame = 'rematch',
	games = {
		rematch = {
			abbreviation = 'Rematch',
			name = 'Rematch',
			link = 'Rematch',
			logo = {
				darkMode = 'Rematch darkmode.png',
				lightMode = 'Rematch lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rematch darkmode.png',
				lightMode = 'Rematch lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = false,
		},
		match2 = {
			status = 0,
			matchWidth = 180,
		},
	},
	defaultRoundPrecision = 0,
}
