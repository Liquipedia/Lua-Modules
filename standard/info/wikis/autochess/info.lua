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
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Auto_Chess_lightmode.png',
				lightMode = 'Auto_Chess_darkmode.png',
			},
		},
	},
	defaultGame = 'autochess',
	defaultTeamLogo = 'Auto_Chess_lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Auto_Chess_darkmode.png', ---@deprecated
}
