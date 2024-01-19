---
-- @Liquipedia
-- wiki=smite
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2013,
	wikiName = 'smite',
	name = 'SMITE',
	games = {
		smite = {
			abbreviation = 'S1',
			name = 'SMITE',
			link = 'SMITE',
			logo = {
				darkMode = 'SMITE default darkmode.png',
				lightMode = 'SMITE default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'SMITE default darkmode.png',
				lightMode = 'SMITE default lightmode.png',
			},
		},
		smite2 = {
			abbreviation = 'S2',
			name = 'SMITE 2',
			link = 'SMITE 2',
			logo = {
				darkMode = 'SMITE 2 default allmode.png',
				lightMode = 'SMITE 2 default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'SMITE default darkmode.png',
				lightMode = 'SMITE default lightmode.png',
			},
		},
	},
	defaultGame = 'smite',
	defaultTeamLogo = 'SMITE default lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'SMITE default darkmode.png', ---@deprecated
	match2 = 2,
}
