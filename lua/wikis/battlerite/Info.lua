---
-- @Liquipedia
-- wiki=battlerite
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2016,
	wikiName = 'battlerite',
	name = 'Battlerite',
	defaultGame = 'battlerite',
	games = {
		battlerite = {
			abbreviation = 'Battlerite',
			name = 'Battlerite',
			link = 'Battlerite',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Battlerite default allmode.png',
				lightMode = 'Battlerite default allmode.png',
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
