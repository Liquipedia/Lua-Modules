---
-- @Liquipedia
-- wiki=deadlock
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2024,
	wikiName = 'deadlock',
	name = 'Deadlock',
	defaultGame = 'Deadlock',
	games = {
		deadlock = {
			abbreviation = 'Deadlock',
			name = 'Deadlock',
			link = 'Deadlock',
			logo = {
				darkMode = 'Deadlock default allmode.png',
				lightMode = 'Deadlock default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Deadlock default allmode.png',
				lightMode = 'Deadlock default allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = false,
		},
		match2 = {
			status = 2,
		},
	},
	defaultRoundPrecision = 0,
}
