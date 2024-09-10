---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2020,
	wikiName = 'wildrift',
	name = 'Wild Rift',
	defaultGame = 'wildrift',
	games = {
		wildrift = {
			abbreviation = 'WR',
			name = 'Wild Rift',
			link = 'Wild Rift',
			logo = {
				darkMode = 'Wild Rift Teamcard.png',
				lightMode = 'Wild Rift Teamcard.png',
			},
			defaultTeamLogo = {
				darkMode = 'Wild Rift Teamcard.png',
				lightMode = 'Wild Rift Teamcard.png',
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
			matchWidthMobile = 110,
			matchWidth = 200,
		},
	},
}
