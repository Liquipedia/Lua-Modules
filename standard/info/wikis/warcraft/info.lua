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
	defaultGame = 'reforged',
	games = {
		reignofchaos = {
			abbreviation = 'RoC',
			name = 'Reign of Chaos',
			link = 'Reign of Chaos',
			logo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
		},
		frozenthrone = {
			abbreviation = 'TFT',
			name = 'The Frozen Throne',
			link = 'The Frozen Throne',
			logo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
		},
		reforged = {
			abbreviation = 'WC3R',
			name = 'Reforged',
			link = 'Reforged',
			logo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Warcraft III default allmode.png',
				lightMode = 'Warcraft III default allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = true,
			allowManual = true,
		},
		match2 = {
			status = 2,
			matchWidthMobile = 110,
			matchWidth = 150,
		},
	},
	opponentLibrary = 'Opponent/Custom',
	opponentDisplayLibrary = 'OpponentDisplay/Custom',
}
