---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2024,
	wikiName = 'predecessor',
	name = 'Predecessor',
	defaultGame = 'Predecessor',
	games = {
		predecessor = {
			abbreviation = 'Predecessor',
			name = 'Predecessor',
			link = 'Predecessor',
			logo = {
				darkMode = 'Predecessor.png',
				lightMode = 'Predecessor.png',
			},
			defaultTeamLogo = {
				darkMode = 'Predecessor.png',
				lightMode = 'Predecessor.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = true,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 2,
		},
		participants = {
			defaultPlayerNumber = 5,
		},
	},
	defaultRoundPrecision = 0,
}
