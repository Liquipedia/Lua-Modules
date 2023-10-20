---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2010,
	wikiName = 'worldoftanks',
	name = 'World of Tanks',
	games = {
		worldoftanks = {
			abbreviation = 'WoT',
			name = 'World of Tanks',
			link = 'World of Tanks',
			logo = {
				darkMode = 'World of Tanks default darkmode.png',
				lightMode = 'World of Tanks default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'World of Tanks default darkmode.png',
				lightMode = 'World of Tanks default lightmode.png',
			},
		},
	},
	defaultGame = 'worldoftanks',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'World of Tanks default lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'World of Tanks default darkmode.png', ---@deprecated
}
