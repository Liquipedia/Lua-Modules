---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2018,
	wikiName = 'fortnite',
	name = 'Fortnite',
	defaultGame = 'fortnite',
	games = {
		fortnite = {
			abbreviation = 'Fortnite',
			name = 'Fortnite',
			link = 'Fortnite',
			logo = {
				darkMode = 'Fortnite default allmode.png',
				lightMode = 'Fortnite default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Fortnite default allmode.png',
				lightMode = 'Fortnite default allmode.png',
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
