---
-- @Liquipedia
-- wiki=goals
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2024,
	wikiName = 'goals',
	name = 'GOALS',
	defaultGame = 'goals',
	games = {
		goals = {
			abbreviation = 'GOALS',
			name = 'GOALS',
			link = 'GOALS',
			logo = {
				darkMode = 'GOALS default allmode.png',
				lightMode = 'GOALS default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'GOALS default allmode.png',
				lightMode = 'GOALS default allmode.png',
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
