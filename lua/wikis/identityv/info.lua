---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2017,
	wikiName = 'identityv',
	name = 'Identity V',
	defaultGame = 'identityv',
	games = {
		identityv = {
			abbreviation = 'IDV',
			name = 'Identity V',
			link = 'Identity V',
			logo = {
				darkMode = 'Identity V Global default darkmode.png',
				lightMode = 'Identity V Global default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Identity V Global default darkmode.png',
				lightMode = 'Identity V Global default lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = true,
			hasSpecialTeam = false,
			allowManual = false,
		},
		match2 = {
			status = 2,
			matchWidth = 180,
		},
		infoboxPlayer = {
			autoTeam = true,
			automatedHistory = {
				mode = 'automatic',
				storeFromWikiCode = true,
			},
		},
	},
}
