---
-- @Liquipedia
-- wiki=paladins
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2016,
	wikiName = 'paladins',
	name = 'Paladins',
	defaultGame = 'paladins',
	games = {
		paladins = {
			abbreviation = 'Paladins',
			name = 'Paladins',
			link = 'Paladins',
			logo = {
				darkMode = 'Paladins allmode.png',
				lightMode = 'Paladins allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Paladins allmode.png',
				lightMode = 'Paladins allmode.png',
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
