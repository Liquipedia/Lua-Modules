---
-- @Liquipedia
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
		cnbrawlstars = {
			abbreviation = 'CN BS',
			name = '荒野乱斗',
			link = '荒野乱斗',
			logo = {
				darkMode = '荒野乱斗 Default logo allmode.png',
				lightMode = '荒野乱斗 Default logo allmode.png',
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
		match2 = {
			status = 2,
			matchWidth = 200,
		},
		teamRosterNavbox = {
			links = {
				playedMatches = 'Matches',
			},
		},
	},
	defaultRoundPrecision = 0,
}
