---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2017,
	wikiName = 'brawlhalla',
	name = 'Brawlhalla',
	defaultGame = 'brawl',
	games = {
		brawl = {
			abbreviation = 'Brawl',
			name = 'Brawlhalla',
			link = 'Brawlhalla',
			logo = {
				darkMode = 'Brawlhalla Default logo.png',
				lightMode = 'Brawlhalla Default logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Brawlhalla Default logo.png',
				lightMode = 'Brawlhalla Default logo.png',
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
			status = 1,
		},
	},
}
