---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2013,
	wikiName = 'hearthstone',
	name = 'Hearthstone',
	defaultGame = 'hs',
	games = {
		hs = {
			abbreviation = 'hs',
			name = 'Hearthstone',
			link = 'Hearthstone',
			logo = {
				darkMode = 'Hearthstone default allmode.png',
				lightMode = 'Hearthstone default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Hearthstone default allmode.png',
				lightMode = 'Hearthstone default allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 0,
		},
	},
}
