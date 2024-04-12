---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2015,
	wikiName = 'mobilelegends',
	name = 'Mobile Legends',
	defaultGame = 'mobilelegends',
	games = {
		mobilelegends = {
			abbreviation = 'ML',
			name = 'Mobile Legends',
			link = 'Mobile Legends',
			logo = {
				darkMode = 'Mobile Legends allmode.png',
				lightMode = 'Mobile Legends allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Mobile Legends allmode.png',
				lightMode = 'Mobile Legends allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = true,
			hasSpecialTeam = false,
			allowManual = true,
		},
	},
	match2 = 2,
}
