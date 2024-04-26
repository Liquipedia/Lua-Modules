---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2018,
	wikiName = 'brawlstars',
	name = 'Brawl Stars',
	defaultGame = 'brawlstars',
	games = {
		brawlstars = {
			abbreviation = 'BS',
			name = 'Brawl Stars',
			link = 'Brawl Stars',
			logo = {
				darkMode = 'Brawl Stars Default allmode.png',
				lightMode = 'Brawl Stars Default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Brawl Stars Default allmode.png',
				lightMode = 'Brawl Stars Default allmode.png',
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
	match2 = 2,
}
