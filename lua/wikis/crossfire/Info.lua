---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2007,
	wikiName = 'crossfire',
	name = 'CrossFire',
	defaultGame = 'cf',
	games = {
		cf = {
			abbreviation = 'Classic',
			name = 'CrossFire',
			link = 'CrossFire',
			logo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
		},
		cfm = {
			abbreviation = 'Mobile',
			name = 'CrossFire Mobile',
			link = 'CrossFire Mobile',
			logo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
		},
		cfhd = {
			abbreviation = 'HD',
			name = 'CrossFire HD',
			link = 'CrossFire HD',
			logo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 1,
			matchWidthMobile = 110,
			matchWidth = 190,
			gameScoresIfBo1 = true,
		},
		transfers = {
			showTeamName = true,
		},
		thisDay = {
			tiers = {1, 2},
			excludeTierTypes = {'Qualifier'},
			showPatches = true,
		},
		infoboxPlayer = {
			automatedHistory = {
				mode = 'merge',
			},
		},
	},
	defaultRoundPrecision = 0,
}
