---
-- @Liquipedia
-- wiki=sideswipe
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2021,
	wikiName = 'sideswipe',
	name = 'Rocket League Sideswipe',
	defaultGame = 'sideswipe',
	games = {
		sideswipe = {
			abbreviation = 'SW',
			name = 'Rocket League Sideswipe',
			link = 'Rocket League Sideswipe',
			logo = {
				darkMode = 'Sideswipe allmode.png',
				lightMode = 'Sideswipe allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Sideswipe allmode.png',
				lightMode = 'Sideswipe allmode.png',
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
		},
	},
}
