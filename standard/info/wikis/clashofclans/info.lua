---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2012,
	wikiName = 'clashofclans',
	name = 'Clash of Clans',
	defaultGame = 'clashofclans',
	games = {
		clashofclans = {
			abbreviation = 'CoC',
			name = 'Clash of Clans',
			link = 'Main Page',
			logo = {
				darkMode = 'Clash of Clans default allmode.png',
				lightMode = 'Clash of Clans default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Clash of Clans default allmode.png',
				lightMode = 'Clash of Clans default allmode.png',
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
			matchWidth = 200,
		},
	},
}
