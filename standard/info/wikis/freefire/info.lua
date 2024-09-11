---
-- @Liquipedia
-- wiki=freefire
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2017,
	wikiName = 'freefire',
	name = 'Free Fire',
	defaultGame = 'freefire',
	games = {
		freefire = {
			abbreviation = 'Free Fire',
			name = 'Free Fire',
			link = 'Free Fire',
			logo = {
				darkMode = 'Freefire Default Logo.png',
				lightMode = 'Freefire Default Logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Freefire Default Logo.png',
				lightMode = 'Freefire Default Logo.png',
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
	defaultRoundPrecision = 0,
}
