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
				darkMode = 'Team Fortress logo.png',
				lightMode = 'Team Fortress logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Team Fortress logo.png',
				lightMode = 'Team Fortress logo.png',
			},
		},
	},
	defaultGame = 'tf2',
	defaultTeamLogo = 'Team Fortress logo.png', ---@deprecated
	defaultTeamLogoDark = 'Team Fortress logo.png', ---@deprecated
	match2 = 0,
}
