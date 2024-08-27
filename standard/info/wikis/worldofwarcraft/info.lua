---
-- @Liquipedia
-- wiki=worldofwarcraft
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2007,
	wikiName = 'worldofwarcraft',
	name = 'World of Warcraft',
	defaultGame = 'wow',
	games = {
		wow = {
			abbreviation = 'WoW',
			name = 'World of Warcraft',
			link = 'World of Warcraft',
			logo = {
				darkMode = 'WoWlogo Default allmode.png',
				lightMode = 'WoWlogo Default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'WoWlogo Default allmode.png',
				lightMode = 'WoWlogo Default allmode.png',
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
