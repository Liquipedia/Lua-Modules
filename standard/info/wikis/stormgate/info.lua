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
	defaultGame = 'stormgate',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'Stormgate default lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Stormgate default darkmode.png', ---@deprecated
	opponentLibrary = 'Opponent/Starcraft',
	opponentDisplayLibrary = 'OpponentDisplay/Starcraft',
}
