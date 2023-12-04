---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1950,
	wikiName = 'formula1',
	name = 'Formula 1',
	games = {
		formula1 = {
			abbreviation = 'F1',
			name = 'Formula 1',
			link = 'Formula 1',
			logo = {
				darkMode = 'F1 2018 allmode.png',
				lightMode = 'F1 2018 allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Sim Racing default darkmode.png',
				lightMode = 'Sim Racing default lightmode.png',
			},
		},
	},
	defaultGame = 'formula1',
	defaultTeamLogo = 'Sim Racing default lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Sim Racing default darkmode.png', ---@deprecated
}
