---
-- @Liquipedia
-- wiki=battalion
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'battalion',
	name = 'Battalion 1944',
	defaultGame = 'battalion',
	games = {
		battalion = {
			abbreviation = 'Battalion',
			name = 'Battalion 1944',
			link = 'Battalion 1944',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Battalion 1944 default darkmode.png',
				lightMode = 'Battalion 1944 default lightmode.png',
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
