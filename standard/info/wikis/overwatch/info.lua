---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2015,
	wikiName = 'overwatch',
	name = 'Overwatch',
	games = {
		overwatch = {
			abbreviation = 'OW',
			name = 'Overwatch',
			link = 'Overwatch',
			logo = {
				darkMode = 'Overwatch default darkmode.png',
				lightMode = 'Overwatch default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Overwatch default darkmode.png',
				lightMode = 'Overwatch default lightmode.png',
			},
		},
		overwatch2 = {
			abbreviation = 'OW2',
			name = 'Overwatch 2',
			link = 'Overwatch 2',
			logo = {
				darkMode = 'Overwatch 2 default darkmode.png',
				lightMode = 'Overwatch 2 default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Overwatch 2 default darkmode.png',
				lightMode = 'Overwatch 2 default lightmode.png',
			},
		},
	},
	defaultGame = 'overwatch2',
	config = {
		squads = {
			hasPosition = true,
			hasSpecialTeam = false,
			allowManual = true,
		},
	},
	match2 = 2,
}
