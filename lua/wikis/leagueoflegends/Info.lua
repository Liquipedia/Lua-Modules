---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2009,
	wikiName = 'leagueoflegends',
	name = 'League of Legends',
	defaultGame = 'leagueoflegends',
	games = {
		leagueoflegends = {
			abbreviation = 'LoL',
			name = 'League of Legends',
			link = 'League of Legends',
			logo = {
				darkMode = 'League of Legends allmode.png',
				lightMode = 'League of Legends allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'League of Legends allmode.png',
				lightMode = 'League of Legends allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = true,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			matchPage = true,
			status = 2,
			matchWidth = 200,
		},
		transfers = {
			showTeamName = true,
			contractDatabase = {
				link = 'https://docs.google.com/spreadsheets/d/1Y7k5kQ2AegbuyiGwEPsa62e883FYVtHqr6UVut9RC4o/pubhtml',
				display = 'LoL Esports League-Recognized Contract Database'
			},
		},
		infoboxPlayer = {
			autoTeam = true,
			automatedHistory = {
				mode = 'manualPrio',
				showRole = false,
			},
		},
	},
	defaultRoundPrecision = 0,
}
