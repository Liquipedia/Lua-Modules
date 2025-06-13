---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1834,
	wikiName = 'chess',
	name = 'Chess',
	defaultGame = 'chess',
	games = {
		chess = {
			abbreviation = 'Chess',
			name = 'Chess',
			link = 'Chess',
			logo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
		},
		chess960 = {
			abbreviation = 'Chess960',
			name = 'Chess960',
			link = 'Chess960',
			logo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Chess default darkmode.png',
				lightMode = 'Chess default lightmode.png',
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
			status = 2,
			matchWidth = 180,
		},
	},
	defaultRoundPrecision = 0,
}
