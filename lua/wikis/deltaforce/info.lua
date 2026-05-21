---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2023,
	wikiName = 'deltaforce',
	name = 'Delta Force',
	defaultGame = 'deltaforce',
	games = {
		deltaforce = {
			abbreviation = 'DF',
			name = 'Delta Force',
			link = 'Delta Force',
			logo = {
				darkMode = 'Delta Force icon allmode.png',
				lightMode = 'Delta Force icon allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Delta Force icon allmode.png',
				lightMode = 'Delta Force icon allmode.png',
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
			},
		},
		participants = {
			defaultPlayerNumber = 3,
		},
	},
}
