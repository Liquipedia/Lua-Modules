---
-- @Liquipedia
-- wiki=simracing
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'simracing',
	name = 'Sim Racing',
	games = {
		sr = {
			abbreviation = 'SR',
			name = 'Sim Racing',
			link = 'Sim Racing',
			logo = {
				darkMode = 'Sim Racing default darkmode.png',
				lightMode = 'Sim Racing default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Sim Racing default darkmode.png',
				lightMode = 'Sim Racing default lightmode.png',
			},
		},
	},
	defaultGame = 'sr',
	defaultTeamLogo = 'Sim Racing default lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Sim Racing default darkmode.png', ---@deprecated
}
