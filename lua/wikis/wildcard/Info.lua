---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2024,
	wikiName = 'wildcard',
	name = 'Wildcard',
	defaultGame = 'Wildcard',
	games = {
		wildcard = {
			abbreviation = 'Wildcard',
			name = 'Wildcard',
			link = 'Wildcard',
			logo = {
				darkMode = 'Wildcard full darkmode.svg',
				lightMode = 'Wildcard full lightmode.svg',
			},
			defaultTeamLogo = {
				darkMode = 'Wildcard full darkmode.svg',
				lightMode = 'Wildcard full lightmode.svg',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = false,
		},
		match2 = {
			status = 0,
			matchWidth = 180,
		},
	},
	defaultRoundPrecision = 0,
}
