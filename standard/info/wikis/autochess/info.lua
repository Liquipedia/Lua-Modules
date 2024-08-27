---
-- @Liquipedia
-- wiki=autochess
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'autochess',
	name = 'Auto Chess',
	defaultGame = 'autochess',
	games = {
		autochess = {
			abbreviation = 'Auto Chess',
			name = 'Auto Chess',
			link = 'Auto Chess',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Auto Chess lightmode.png',
				lightMode = 'Auto Chess darkmode.png',
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
