---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2017,
	wikiName = 'eva',
	name = 'EVA',
	defaultGame = 'eva',
	games = {
		eva= {
			abbreviation = 'EVA',
			name = 'EVA',
			link = 'Esports Virtual Arena',
			logo = {
				darkMode = 'EVA lightmode.png',
				lightMode = 'EVA darkmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'EVA lightmode.png',
				lightMode = 'EVA darkmode.png',
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
	},
}
