---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2020,
	wikiName = 'valorant',
	name = 'VALORANT',
	games = {
		val = {
			abbreviation = 'VAL',
			name = 'VALORANT',
			link = 'VALORANT',
			logo = {
				darkMode = 'VALORANT allmode.png',
				lightMode = 'VALORANT allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'VALORANT allmode.png',
				lightMode = 'VALORANT allmode.png',
			},
		},
	},
	defaultGame = 'val',
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = true,
			allowManual = true,
		},
	},
	match2 = 2,
}
