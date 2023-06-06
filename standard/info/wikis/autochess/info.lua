---
-- @Liquipedia
-- wiki=autochess
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'autochess',
	name = 'Auto Chess',
	games = {
		autochess = {
			abbreviation = 'Auto Chess',
			name = 'Auto Chess',
			link = 'Auto Chess',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Auto Chess lightmode.png',
				lightMode = 'Auto Chess darkmode.png',
			},
		},
	},
	defaultGame = 'autochess',
	defaultTeamLogo = 'Auto Chess lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Auto Chess darkmode.png', ---@deprecated
}
