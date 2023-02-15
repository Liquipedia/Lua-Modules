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
		todo = {
			abbreviation = 'todo',
			name = 'TODO',
			link = 'Main Page',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Sim Racing default darkmode.png',
				lightMode = 'Sim Racing default lightmode.png',
			},
		},
	},
	defaultGame = 'todo',
	defaultTeamLogo = 'Sim Racing default lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Sim Racing default darkmode.png', ---@deprecated
}
