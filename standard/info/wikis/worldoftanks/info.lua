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
		['wot blitz'] = {
			abbreviation = 'WoT Blitz',
			name = 'World of Tanks Blitz',
			link = 'World of Tanks Blitz',
			logo = {
				darkMode = 'World of Tanks Blitz default darkmode.png',
				lightMode = 'World of Tanks Blitz default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'World of Tanks default darkmode.png',
				lightMode = 'World of Tanks default lightmode.png',
			},
		},
		['mir tankov'] = {
			abbreviation = 'Tanki',
			name = 'Mir Tankov',
			link = 'Mir Tankov',
			logo = {
				darkMode = 'Mir Tankov default darkmode.png',
				lightMode = 'Mir Tankov default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'World of Tanks default darkmode.png',
				lightMode = 'World of Tanks default lightmode.png',
			},
		},
		['tanks blitz'] = {
			abbreviation = 'Tanks Blitz',
			name = 'Tanks Blitz',
			link = 'Tanks Blitz',
			logo = {
				darkMode = 'Tanks Blitz default darkmode.png',
				lightMode = 'Tanks Blitz default lightmode.png',
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
