---
-- @Liquipedia
-- wiki=teamfortress
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2007,
	wikiName = 'teamfortress',
	name = 'Team Fortress',
	games = {
		tf2 = {
			abbreviation = 'TF2',
			name = 'Team Fortress 2',
			link = 'Team Fortress 2',
			logo = {
				darkMode = 'Team Fortress default allmode.png',
				lightMode = 'Team Fortress default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Team Fortress default allmode.png',
				lightMode = 'Team Fortress default allmode.png',
			},
		},
	},
	defaultGame = 'tf2',
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
	},
	match2 = 0,
}
