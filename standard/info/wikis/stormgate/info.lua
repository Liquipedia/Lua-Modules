---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2023,
	wikiName = 'stormgate',
	name = 'Stormgate',
	defaultGame = 'stormgate',
	games = {
		stormgate = {
			abbreviation = 'SG',
			name = 'Stormgate',
			link = 'Stormgate',
			logo = {
				darkMode = 'Stormgate default darkmode.png',
				lightMode = 'Stormgate default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Stormgate default darkmode.png',
				lightMode = 'Stormgate default lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
	},
	defaultRoundPrecision = 0,
	opponentLibrary = 'Opponent/Custom',
	opponentDisplayLibrary = 'OpponentDisplay/Custom',
	match2 = 2,
}
