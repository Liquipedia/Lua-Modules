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
				darkMode = 'Rainbow Six Siege default darkmode.png',
				lightMode = 'Rainbow Six Siege default lightmode.png',
			},
		},
		vegas2 = {
			abbreviation = 'R6V2',
			name = 'Tom Clancy\'s Rainbow Six Vegas 2',
			link = 'Rainbow Six Vegas 2',
			logo = {
				darkMode = 'Rainbow Six Vegas 2 icon allmode.png',
				lightMode = 'Rainbow Six Vegas 2 icon allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rainbow Six Vegas default darkmode.png',
				lightMode = 'Rainbow Six Vegas default lightmode.png',
			},
		},
		vegas = {
			abbreviation = 'R6V',
			name = 'Tom Clancy\'s Rainbow Six Vegas',
			link = 'Rainbow Six Vegas',
			logo = {
				darkMode = 'Rainbow Six Vegas 2 icon allmode.png',
				lightMode = 'Rainbow Six Vegas 2 icon allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rainbow Six Vegas default darkmode.png',
				lightMode = 'Rainbow Six Vegas default lightmode.png',
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
			gameScoresIfBo1 = true,
		},
		infoboxPlayer = {
			autoTeam = true,
			automatedHistory = {
				mode = 'automatic',
				hasHeaderAndRefs = true,
			},
		},
	},
	defaultRoundPrecision = 0,
}
