---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2002,
	wikiName = 'warcraft',
	name = 'Warcraft',
	games = {
		reignofchaos = {
			abbreviation = 'RoC',
			name = 'Reign of Chaos',
			link = 'Reign of Chaos',
			logo = {
				darkMode = 'Warcraft III logo.png',
				lightMode = 'Warcraft III logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III logo.png',
				lightMode = 'Warcraft III logo.png',
			},
		},
		frozenthrone = {
			abbreviation = 'TFT',
			name = 'The Frozen Throne',
			link = 'The Frozen Throne',
			logo = {
				darkMode = 'Warcraft III logo.png',
				lightMode = 'Warcraft III logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III logo.png',
				lightMode = 'Warcraft III logo.png',
			},
		},
		reforged = {
			abbreviation = 'WC3R',
			name = 'Reforged',
			link = 'Reforged',
			logo = {
				darkMode = 'Warcraft III logo.png',
				lightMode = 'Warcraft III logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III logo.png',
				lightMode = 'Warcraft III logo.png',
			},
		},
	},
	defaultGame = 'reforged',
	defaultTeamLogo = 'Warcraft III logo.png', ---@deprecated
	defaultTeamLogoDark = 'Warcraft III logo.png', ---@deprecated
	opponentLibrary = 'Opponent/Custom',
	opponentDisplayLibrary = 'OpponentDisplay/Custom',
	match2 = 2,
}
