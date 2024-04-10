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
	defaultGame = 'cf',
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
	},
	defaultRoundPrecision = 0,
	match2 = 1,
}
