---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2016,
	wikiName = 'standoff2',
	name = 'Standoff 2',
	defaultGame = 'standoff2',
	games = {
		standoff2 = {
			abbreviation = 'SO2',
			name = 'Standoff 2',
			link = 'Standoff 2',
			logo = {
				darkMode = 'Standoff 2 default darkmode.png',
				lightMode = 'Standoff 2 default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Standoff 2 default darkmode.png',
				lightMode = 'Standoff 2 default lightmode.png',
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
		infoboxPlayer = {
			autoTeam = true,
			automatedHistory = {
				mode = 'automatic',
				storeFromWikiCode = true,
			},
		},
		participants = {
			defaultPlayerNumber = 5,
		},
		standings = {
			alwaysShowStats = {
				swiss = {'matchdiff', 'gamediff'},
			},
		},
	},
}
