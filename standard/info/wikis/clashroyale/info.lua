---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2016,
	wikiName = 'clashroyale',
	name = 'Clash Royale',
	defaultGame = 'cr',
	games = {
		cr = {
			abbreviation = 'CR',
			name = 'Clash Royale',
			link = 'Clash Royale',
			logo = {
				darkMode = 'Clash Royale default allmode.png',
				lightMode = 'Clash Royale default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Clash Royale default allmode.png',
				lightMode = 'Clash Royale default allmode.png',
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
			matchWidthMobile = 110,
			matchWidth = 170,
		},
	},
}
