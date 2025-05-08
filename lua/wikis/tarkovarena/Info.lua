---
-- @Liquipedia
-- wiki=tarkovarena
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2023,
	wikiName = 'tarkovarena',
	name = 'Escape from Tarkov: Arena',
	defaultGame = 'Escape from Tarkov: Arena',
	games = {
		tarkovarena = {
			abbreviation = 'EFT Arena',
			name = 'Escape from Tarkov: Arena',
			link = 'Escape from Tarkov: Arena',
			logo = {
				darkMode = 'Tarkov Arena default allmode.png',
				lightMode = 'Tarkov Arena default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Tarkov Arena default allmode.png',
				lightMode = 'Tarkov Arena default allmode.png',
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
			},
		},
	},
	defaultRoundPrecision = 0,
}
