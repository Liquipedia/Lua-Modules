---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2006, --vegas from 2006; vegas2 from 2008; siege from 2015
	wikiName = 'rainbowsix',
	name = 'Rainbow Six',
	defaultGame = 'siege',
	games = {
		siege = {
			abbreviation = 'R6S',
			name = 'Tom Clancy\'s Rainbow Six Siege',
			link = 'Rainbow Six Siege',
			logo = {
				darkMode = 'Rainbow Six Siege gameicon darkmode.png',
				lightMode = 'Rainbow Six Siege gameicon lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rainbow Six Siege Logo darkmode.png',
				lightMode = 'Rainbow Six Siege Logo lightmode.png',
			},
		},
		vegas2 = {
			abbreviation = 'R6V2',
			name = 'Tom Clancy\'s Rainbow Six Vegas 2',
			link = 'Rainbow Six Vegas 2',
			logo = {
				darkMode = 'R6 Vegas 2 icon.png',
				lightMode = 'R6 Vegas 2 icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rainbow Six Vegas Logo darkmode.png',
				lightMode = 'Rainbow Six Vegas Logo lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = false,
		},
		match2 = {
			status = 2,
			matchWidth = 180,
		},
	},
	defaultRoundPrecision = 0,
}
