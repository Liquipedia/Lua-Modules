---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1998,
	wikiName = 'starcraft',
	name = 'Brood War',
	maximumNumberOfPlayersInPlacements = 35,
	games = {
		bw = {
			abbreviation = 'BW',
			name = 'Brood War',
			link = 'Brood War',
			logo = {
				darkMode = 'StarCraft default allmode.png',
				lightMode = 'StarCraft default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'StarCraft default allmode.png',
				lightMode = 'StarCraft default allmode.png',
			},
		},
	},
	defaultGame = 'bw',
	defaultTeamLogo = 'StarCraft default allmode.png', ---@deprecated
	defaultTeamLogoDark = 'StarCraft default allmode.png', ---@deprecated

	opponentLibrary = 'Opponent/Starcraft',
	opponentDisplayLibrary = 'OpponentDisplay/Starcraft',
	match2 = 1,
}
