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
	},
	defaultRoundPrecision = 0,
	match2 = 2,
}
