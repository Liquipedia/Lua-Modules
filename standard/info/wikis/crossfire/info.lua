---
-- @Liquipedia
-- wiki=crossfire
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2007,
	wikiName = 'crossfire',
	name = 'Crossfire',
	defaultGame = 'cf',
	games = {
		cf = {
			abbreviation = 'CF',
			name = 'Crossfire',
			link = 'Crossfire',
			logo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
		},
		cfm = {
			abbreviation = 'CFM',
			name = 'Crossfire Mobile',
			link = 'Crossfire Mobile',
			logo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
		},
		cfhd = {
			abbreviation = 'CFHD',
			name = 'Crossfire HD',
			link = 'Crossfire HD',
			logo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Crossfire default darkmode.png',
				lightMode = 'Crossfire default lightmode.png',
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
			matchWidthMobile = 110,
			matchWidth = 190,
		},
	},
	defaultRoundPrecision = 0,
}
