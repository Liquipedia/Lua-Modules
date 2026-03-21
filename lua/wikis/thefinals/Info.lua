---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2023,
	wikiName = 'thefinals',
	name = 'The Finals',
	defaultGame = 'thefinals',
	games = {
		thefinals = {
			abbreviation = 'TF',
			name = 'The Finals',
			link = 'The Finals',
			logo = {
				darkMode = 'The Finals default darkmode.png',
				lightMode = 'The Finals default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'The Finals default darkmode.png',
				lightMode = 'The Finals default lightmode.png',
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
	},
}
