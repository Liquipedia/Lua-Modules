---
-- @Liquipedia
-- wiki=commons
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	wikiName = 'commons',
	name = 'Commons',
	defaultGame = 'commons',
	games = {
		commons = {
			abbreviation = 'Commons',
			name = 'Commons',
			link = 'lpcommons:Main Page',
			logo = {
				darkMode = 'Liquipedia logo.png',
				lightMode = 'Liquipedia logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Liquipedia logo.png',
				lightMode = 'Liquipedia logo.png',
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
		},
	},
}
