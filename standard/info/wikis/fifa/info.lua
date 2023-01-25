---
-- @Liquipedia
-- wiki=fifa
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2000,
	wikiName = 'fifa',
	name = 'FIFA',
	games = {
		fifa = {
			abbreviation = 'FIFA',
			name = 'FIFA',
			link = 'FIFA',
			logo = {
				darkMode = 'FIFA darkmode logo.png',
				lightMode = 'FIFA lightmode logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'FIFA darkmode logo.png',
				lightMode = 'FIFA lightmode logo.png',
			},
		},
	},
	defaultGame = 'fifa',
	defaultTeamLogo = 'FIFA lightmode logo.png', ---@deprecated
	defaultTeamLogoDark = 'FIFA darkmode logo.png', ---@deprecated
}
