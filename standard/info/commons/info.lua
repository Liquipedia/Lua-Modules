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
		transfers = {
			displayTeamName = false, -- bool
			iconFunction = nil, -- string?
			iconModule = nil, -- string?
			iconParam = 'pos', -- string?
			iconTransfers = false, -- bool
			platformIcons = false, -- bool
			positionConvert = nil, -- string?
			referencesAsTable = false, -- bool
			syncPlayers = false, -- bool
		},
	},
	match2 = 2,
}
