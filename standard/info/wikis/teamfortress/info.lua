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
				darkMode = 'Team_Fortress_logo.png',
				lightMode = 'Team_Fortress_logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Team_Fortress_logo.png',
				lightMode = 'Team_Fortress_logo.png',
			},
		},
	},
	defaultGame = 'tf2',
	defaultTeamLogo = 'Team_Fortress_logo.png', ---@deprecated
	defaultTeamLogoDark = 'Team_Fortress_logo.png', ---@deprecated
}
